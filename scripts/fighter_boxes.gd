class_name FighterBoxes
extends Resource

## Cajas de colision por pose de un combatiente.
##
## Cada pose puede tener varias hitboxes (zonas que golpean) y varias hurtboxes
## (zonas vulnerables), para que la silueta de colision se parezca al dibujo y no
## sea un rectangulo generico pegado al torso.
##
## Coordenadas en el MISMO espacio que los nodos de colision del Fighter:
## origen en el nodo raiz del Fighter (centro del cuerpo), +x hacia donde mira el
## personaje, +y hacia abajo. Los pies del personaje estan en `y = FEET_OFFSET`
## (actualmente +50), NO en y = 0. Ver `Fighter.FEET_OFFSET`.
##
## Las cajas se guardan mirando a la derecha; `Fighter._mirror_boxes()` las
## refleja en runtime cuando el personaje mira a la izquierda.
##
## Las cajas se autoran con el plugin de editor `FighterBoxEditor`, que las
## dibuja encima del spritesheet y compensa el offset de pies por ti.

## Nombre de la pose -> Array[Rect2] (zonas que golpean).
## Solo las poses de ataque tienen hitboxes.
@export var hitboxes: Dictionary = {}

## Nombre de la pose -> Array[Rect2] (zonas vulnerables).
## Todas las poses tienen hurtboxes.
@export var hurtboxes: Dictionary = {}


## Devuelve las hitboxes de una pose (Array[Rect2]; vacio si no tiene).
func get_hitboxes(pose: String) -> Array:
	return hitboxes.get(pose, [])


## Devuelve las hurtboxes de una pose (Array[Rect2]; vacio si no tiene).
func get_hurtboxes(pose: String) -> Array:
	return hurtboxes.get(pose, [])


## ?Tiene esta pose cajas definidas?
func has_pose(pose: String) -> bool:
	return hurtboxes.has(pose) or hitboxes.has(pose)
