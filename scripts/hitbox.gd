class_name Hitbox
extends Area2D

## Area de impacto de un ataque.
##
## Se mantiene con `monitoring = true` de forma permanente para que la lista de
## solapamientos (`get_overlapping_areas`) este siempre actualizada; el Fighter
## propietario es quien decide cuando leerla (solo en los frames activos y con
## `set_active`). Esto evita el retardo de un frame que ocurre al alternar
## `monitoring` en caliente.
##
## Soporta VARIAS cajas por pose, igual que la Hurtbox: un golpe puede tener el
## puno y el pie como zonas de impacto separadas.

var fighter: Node = null  # Referencia al Fighter dueno de esta hitbox.
var is_active: bool = false

## Nodo contenedor de las CollisionShape2D. Se crea en runtime si no existe.
var _shape_root: Node = null


func _ready() -> void:
	# Una hitbox nunca debe ser detectada por otras hitboxes...
	monitorable = false
	# ...pero si necesita detectar las hurtbox rivales en todo momento.
	monitoring = true
	_shape_root = get_node_or_null("Shapes")


## Marca la hitbox como activa o inactiva (bandera logica).
func set_active(active: bool) -> void:
	is_active = active


## Reemplaza las cajas de colision por las de una pose.
## `boxes` es un Array de Rect2 en el mismo espacio local que el Fighter
## (origen en el centro del cuerpo; los pies estan en FEET_OFFSET, +50).
func set_boxes(boxes: Array) -> void:
	if _shape_root == null:
		_shape_root = get_node_or_null("Shapes")
		if _shape_root == null:
			_shape_root = Node2D.new()
			_shape_root.name = "Shapes"
			add_child(_shape_root)

	while _shape_root.get_child_count() < boxes.size():
		var cs := CollisionShape2D.new()
		cs.shape = RectangleShape2D.new()
		_shape_root.add_child(cs)

	var i := 0
	for box in boxes:
		var cs := _shape_root.get_child(i) as CollisionShape2D
		var rect: Rect2 = box
		var shape := cs.shape as RectangleShape2D
		if shape == null:
			shape = RectangleShape2D.new()
			cs.shape = shape
		shape.size = rect.size
		cs.position = rect.position + rect.size * 0.5
		cs.disabled = false
		i += 1

	for j in range(i, _shape_root.get_child_count()):
		var cs := _shape_root.get_child(j) as CollisionShape2D
		if cs:
			cs.disabled = true


