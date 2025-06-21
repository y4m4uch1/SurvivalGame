extends StaticBody2D

@export var max_health: int = 5  # Maximum health of the vine
var current_health: int

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	var ground_node = get_tree().root.get_node("/root/Ground")
	if ground_node:
		var vine_instance = create_vine_fiber_item()
		vine_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
		ground_node.add_child(vine_instance)
	queue_free()

func create_vine_fiber_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var vine = item_scene.instantiate()
	vine.item_name = "Vine"  # Ensure this item exists in ItemDatabase.gd
	return vine
