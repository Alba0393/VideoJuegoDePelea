class_name FighterPoses
extends RefCounted

## Lista canonica de poses de un combatiente.
##
## Fuente unica de verdad: la usan `Fighter._current_pose()` (para pedir la pose)
## y el plugin de editor `FighterBoxEditor` (para ofrecer la lista al usuario).
##
## El orden de POSE_ORDER es el orden en el que se esperan las celdas en el
## spritesheet, leyendo de izquierda a derecha y fila por fila.
##
## Los nombres deben coincidir EXACTAMENTE con los que devuelve `_current_pose()`
## y con los valores de `Fighter.ATTACK_POSES`.

const POSE_ORDER := [
	"idle_0", "idle_1",
	"walk_0", "walk_1", "walk_2", "walk_3",
	"jump", "fall",
	"crouch", "dash",
	"block_ground", "block_air",
	"hurt", "ko",
	"light", "medium", "heavy", "special",
	"air_light", "air_medium", "air_heavy", "air_special",
]

## Poses que golpean: solo estas tienen hitboxes.
const ATTACK_POSES := [
	"light", "medium", "heavy", "special",
	"air_light", "air_medium", "air_heavy", "air_special",
]


## ?Esta pose lanza un golpe (y por tanto necesita hitbox)?
static func is_attack(pose: String) -> bool:
	return ATTACK_POSES.has(pose)
