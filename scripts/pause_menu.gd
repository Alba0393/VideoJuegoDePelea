class_name PauseMenu
extends CanvasLayer

## Menú de pausa (ESC). Muestra los combos disponibles y los controles, y
## permite continuar. Se construye de forma dinámica desde ComboRecipes para
## que la lista siempre coincida con las recetas reales del juego.

signal paused_changed(paused: bool)
## Emitido cuando el jugador elige otro nivel. Se aplica al empezar un combate.
signal difficulty_selected(level: int)
## Emitido al pedir reiniciar el combate desde el menu.
signal restart_requested

@onready var resume_button: Button = $Root/Panel/Resume
@onready var restart_button: Button = $Root/Panel/Restart
@onready var quit_button: Button = $Root/Panel/QuitMenu
@onready var combo_root: HBoxContainer = $Root/Panel/ComboScroll/ComboCols
@onready var ground_col: VBoxContainer = $Root/Panel/ComboScroll/ComboCols/GroundCol
@onready var air_col: VBoxContainer = $Root/Panel/ComboScroll/ComboCols/AirCol
@onready var diff_buttons: Array[Button] = [
	$Root/Panel/DiffRow/DiffEasy,
	$Root/Panel/DiffRow/DiffNormal,
	$Root/Panel/DiffRow/DiffExpert,
]

var _difficulty: int = AIBrain.Difficulty.NORMAL


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_resume)
	restart_button.pressed.connect(_request_restart)
	quit_button.pressed.connect(_quit)
	_build_combo_list()
	_wire_difficulty()
	_refresh_difficulty()


func _wire_difficulty() -> void:
	for i in diff_buttons.size():
		diff_buttons[i].pressed.connect(_on_difficulty_pressed.bind(i))


func _on_difficulty_pressed(level: int) -> void:
	_apply_difficulty(level)


## Fija el nivel mostrado sin emitir la senal (para sincronizar al abrir).
func set_difficulty(level: int) -> void:
	_apply_difficulty(level, false)


func get_difficulty() -> int:
	return _difficulty


func _apply_difficulty(level: int, notify: bool = true) -> void:
	_difficulty = clampi(level, 0, diff_buttons.size() - 1)
	_refresh_difficulty()
	if notify:
		difficulty_selected.emit(_difficulty)


func _refresh_difficulty() -> void:
	for i in diff_buttons.size():
		var selected: bool = i == _difficulty
		diff_buttons[i].disabled = selected
		diff_buttons[i].modulate = Color(1, 1, 1, 1) if selected else Color(1, 1, 1, 0.75)


func _build_combo_list() -> void:
	for c in [ground_col, air_col]:
		for child in c.get_children():
			child.queue_free()

	_add_section(ground_col, "— TIERRA —")
	for recipe in ComboRecipes.RECIPES:
		if not recipe["air"]:
			_add_row(ground_col, recipe)

	_add_section(air_col, "— AÉREOS —")
	for recipe in ComboRecipes.RECIPES:
		if recipe["air"]:
			_add_row(air_col, recipe)


func _add_section(col: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.35))
	col.add_child(label)


func _add_row(col: VBoxContainer, recipe: Dictionary) -> void:
	var row := Label.new()
	row.text = "%s  ·  %s" % [recipe["name"], ComboRecipes.describe_short(recipe["seq"])]
	row.add_theme_font_size_override("font_size", 14)
	row.add_theme_color_override("font_color", Color(0.88, 0.90, 0.96))
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(row)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	_set_paused(not get_tree().paused)


func is_paused() -> bool:
	return get_tree().paused


func _resume() -> void:
	_set_paused(false)


func _request_restart() -> void:
	_set_paused(false)
	restart_requested.emit()


func _quit() -> void:
	get_tree().quit()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
	if paused:
		resume_button.grab_focus()
	paused_changed.emit(paused)
