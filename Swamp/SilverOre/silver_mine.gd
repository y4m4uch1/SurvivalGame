extends StaticBody2D

@export var max_health: int = 20  # Máu của tảng đá
var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()  # Load item_data

var current_health: int
var required_tool: String = "PickAxe"  # Công cụ cần thiết
var required_tier: int = 2  # Cần tier 1 (StonePickAxe) để đào

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health -= amount
	# Play the hit sound
	$AudioStreamPlayer2D.play()
	if current_health <= 0:
		break_silver()

func break_silver():
	# Tìm node Ground để thêm Rock vào
	var ground_node = get_tree().root.get_node("Ground")
	if ground_node:
		for i in range(3):  # Tạo 3 mảnh đá
			var silver_instance = create_silver_item()
			silver_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			ground_node.add_child(silver_instance)
			# Không thêm Rock vào spawned_entities của spawner nữa
	
	# Tìm spawner và xóa entity (tảng đá) khỏi danh sách
	var spawner = find_spawner_for_entity()
	if spawner:
		spawner.remove_entity(self)
	
	queue_free()

func create_silver_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var silver = item_scene.instantiate()
	
	# Gán thuộc tính cho item
	silver.item_name = "Silver"
	return silver

func get_required_tool() -> String:
	return required_tool

func get_required_tier() -> int:
	return required_tier

func find_spawner_for_entity() -> Node:
	var root = get_tree().root
	var spawners = []
	find_spawners_recursive(root, spawners)
	for spawner in spawners:
		for entity_data in spawner.spawned_entities:
			if entity_data["instance"] == self:
				return spawner
	return null

func find_spawners_recursive(node: Node, spawners: Array) -> void:
	if node.get_script() and node.get_script().resource_path == "res://World/Scripts/spawnObj.gd":
		spawners.append(node)
	for child in node.get_children():
		find_spawners_recursive(child, spawners)
