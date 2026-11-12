class_name Hurtbox
extends Area2D

## Zona vulnerable del combatiente. No detecta nada por si misma (monitoring = false),
## simplemente existe en una capa de fisica para que las Hitbox puedan encontrarla.
##
## Soporta VARIAS cajas simultaneas: una pose puede tener el torso y la pierna
## extendida como zonas vulnerables separadas, en vez de un rectangulo unico
## pegado al centro. Las formas se reconstruyen llamando a `set_boxes`.

var fighter: Node = null  # Referencia al Fighter dueno de esta hurtbox.

## Nodo contenedor de las CollisionShape2D. Se crea en runtime si no existe.
var _shape_root: Node = null


func _ready() -> void:
	monitoring = false
	monitorable = true
	_shape_root = get_node_or_null("Shapes")


## Reemplaza las cajas de colision por las de una pose.
## `boxes` es un Array de Rect2 en espacio local del Fighter (origen en los pies).
func set_boxes(boxes: Array) -> void:
	if _shape_root == null:
		_shape_root = get_node_or_null("Shapes")
		if _shape_root == null:
			_shape_root = Node2D.new()
			_shape_root.name = "Shapes"
			add_child(_shape_root)

	# Recicla los nodos existentes en vez de recrearlos cada frame.
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

	# Desactiva (no borra) las sobrantes: borrar y recrear cada frame es caro.
	for j in range(i, _shape_root.get_child_count()):
		var cs := _shape_root.get_child(j) as CollisionShape2D
		if cs:
			cs.disabled = true
