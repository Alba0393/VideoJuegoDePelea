class_name AIBrain
extends RefCounted

## IA para el combatiente controlado por la máquina.
##
## Devuelve un diccionario de "intención" con el mismo formato que el input
## humano, de modo que el controlador del personaje es agnóstico a quién lo
## maneja. Sabe usar los tres tipos de ataque, el especial, el doble salto y el
## bloqueo aéreo.
##
## El nivel de dificultad se fija con `set_difficulty()` y solo debería cambiarse
## entre rondas: la IA lo aplica a partir de la siguiente decisión.

enum Difficulty { FACIL, NORMAL, EXPERTO }

const DIFFICULTY_NAMES := {
	Difficulty.FACIL: "FÁCIL",
	Difficulty.NORMAL: "NORMAL",
	Difficulty.EXPERTO: "EXPERTO",
}

## Presets por nivel. Cada valor regula "cuánto de bien" juega la IA.
const PRESETS := {
	Difficulty.FACIL: {
		"decision_min": 0.34,        # piensa despacio
		"decision_max": 0.62,
		"block_chance": 0.22,        # casi nunca bloquea
		"block_range_bonus": 10.0,
		"attack_range_bonus": -10.0, # ataca desde lejos (falla más)
		"attack_commit": 0.5,        # a veces se queda mirando
		"combo_chance": 0.0,         # no encadena combos
		"special_chance": 0.06,
		"anti_air_chance": 0.15,     # mal contra el aéreo
		"dash_chance": 0.05,
		"whiff_chance": 0.30,        # errores aleatorios
	},
	Difficulty.NORMAL: {
		"decision_min": 0.10,
		"decision_max": 0.30,
		"block_chance": 0.70,
		"block_range_bonus": 34.0,
		"attack_range_bonus": 0.0,
		"attack_commit": 0.8,
		"combo_chance": 0.25,
		"special_chance": 0.12,
		"anti_air_chance": 0.45,
		"dash_chance": 0.12,
		"whiff_chance": 0.10,
	},
	Difficulty.EXPERTO: {
		"decision_min": 0.04,        # reacciona casi por frame
		"decision_max": 0.12,
		"block_chance": 0.95,
		"block_range_bonus": 48.0,
		"attack_range_bonus": 8.0,   # ataca solo cuando alcanza de verdad
		"attack_commit": 0.95,
		"combo_chance": 0.75,        # encadena secuencias reales
		"special_chance": 0.20,
		"anti_air_chance": 0.85,     # castiga los saltos
		"dash_chance": 0.22,
		"whiff_chance": 0.0,
	},
}

## Secuencias que el nivel EXPERTO intenta encadenar.
const COMBOS := [
	["light", "light", "medium"],
	["light", "medium", "heavy"],
	["medium", "heavy"],
]

var _decision_timer: float = 0.0
var _action: String = "approach"
var _rng := RandomNumberGenerator.new()
var _difficulty: Difficulty = Difficulty.NORMAL
var _preset: Dictionary = PRESETS[Difficulty.NORMAL]
var _combo: Array = []
var _combo_step: int = 0

const APPROACH_RANGE: float = 120.0
const ATTACK_RANGE: float = 92.0


func _init() -> void:
	_rng.randomize()


func set_difficulty(level: Difficulty) -> void:
	_difficulty = level
	_preset = PRESETS.get(level, PRESETS[Difficulty.NORMAL])
	_combo_step = 0
	_combo = []
	_decision_timer = 0.0
	_action = "approach"


func get_difficulty() -> Difficulty:
	return _difficulty


func get_difficulty_name() -> String:
	return DIFFICULTY_NAMES.get(_difficulty, "NORMAL")


func _p(key: String) -> float:
	return float(_preset.get(key, 0.0))


func think(self_f, opp, delta: float) -> Dictionary:
	var cmd := {
		"move_dir": 0.0,
		"jump": false,
		"crouch": false,
		"dash": false,
		"attack": "",
	}

	if self_f == null or opp == null:
		return cmd
	if self_f.is_ko() or opp.is_ko():
		return cmd

	var dx: float = opp.global_position.x - self_f.global_position.x
	var dist: float = absf(dx)
	var toward: float = signf(dx)
	var airborne: bool = not self_f.is_on_floor()

	# Reacción defensiva: si el rival ataca cerca, retroceder para bloquear.
	# Cuanto más alto el nivel, más rango detecta y más fiable es el bloqueo.
	if dist < ATTACK_RANGE + _p("block_range_bonus") and opp.is_attacking():
		if _rng.randf() < _p("block_chance"):
			cmd["move_dir"] = -toward
			return cmd

	# Rival en el aire cerca: los niveles altos lo castigan (anti-air).
	if airborne and opp_is_moving_up(opp) and dist < ATTACK_RANGE + 40.0:
		if _rng.randf() < _p("anti_air_chance"):
			cmd["move_dir"] = toward * 0.4
			cmd["attack"] = "medium"
			return cmd

	# Refrescar el "plan" cada cierto tiempo (el nivel define cuánto tarda).
	_decision_timer -= delta
	if _decision_timer <= 0.0:
		_decision_timer = _rng.randf_range(_p("decision_min"), _p("decision_max"))
		_action = _choose_action(dist, airborne, toward)

	match _action:
		"approach":
			cmd["move_dir"] = toward
			if airborne and dist > 90.0 and _rng.randf() < 0.25:
				cmd["jump"] = true   # doble salto para perseguir
		"retreat":
			cmd["move_dir"] = -toward
			cmd["crouch"] = dist > 220.0
		"jump":
			cmd["move_dir"] = toward
			if self_f.is_on_floor() or _rng.randf() < 0.3:
				cmd["jump"] = true
		"dash":
			cmd["move_dir"] = toward
			cmd["dash"] = true
		"attack":
			if _rng.randf() < _p("whiff_chance"):
				cmd["move_dir"] = toward * 0.5   # error: se acerca sin golpear
				return cmd
			var reach: float = ATTACK_RANGE + _p("attack_range_bonus") + (14.0 if airborne else 0.0)
			if dist < reach:
				cmd["attack"] = _pick_attack(airborne, toward)
			else:
				cmd["move_dir"] = toward
				if airborne and dist < 110.0:
					cmd["attack"] = _pick_attack(true, toward)
		"block":
			cmd["move_dir"] = -toward

	return cmd


# Pequeño ayudante: el rival va subiendo (para el anti-air).
func opp_is_moving_up(opp) -> bool:
	if opp == null:
		return false
	if not ("velocity" in opp):
		return false
	return float(opp.velocity.y) < -30.0


func _choose_action(dist: float, airborne: bool, toward: float) -> String:
	var r: float = _rng.randf()

	if airborne:
		if dist < 110.0 and r < 0.6:
			return "attack"
		return "approach"

	if dist > APPROACH_RANGE:
		if r < 0.72:
			return "approach"
		elif r < 0.84:
			return "jump"
		elif r < 0.92 and _rng.randf() < _p("dash_chance") + 0.1:
			return "dash"
		return "block"

	if dist > 50.0:
		if r < 0.62:
			return "attack"
		elif r < 0.8:
			return "approach"
		return "retreat"

	if r < 0.4:
		return "attack"
	if r < 0.6:
		return "retreat"
	return "approach"


func _pick_attack(airborne: bool, toward: float) -> String:
	# Nivel EXPERTO: encadena una secuencia real en vez de golpes sueltos.
	if not airborne and _rng.randf() < _p("combo_chance"):
		if _combo.is_empty() or _combo_step >= _combo.size():
			_combo = COMBOS[_rng.randi_range(0, COMBOS.size() - 1)].duplicate()
			_combo_step = 0
		var move: String = _combo[_combo_step]
		_combo_step += 1
		return move

	var r: float = _rng.randf()
	if airborne:
		if r < 0.45:
			return "light"
		elif r < 0.75:
			return "medium"
		elif r < 0.9:
			return "heavy"
		return "special"
	if r < 0.4:
		return "light"
	elif r < 0.68:
		return "medium"
	elif r < 0.88 - _p("special_chance"):
		return "heavy"
	return "special"
