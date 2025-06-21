extends StaticBody2D

@export var max_health: int = 25  # Máu của mỏ vàng, cao hơn mỏ sắt
var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()  # Load item_data

var current_health: int
var required_tool: String = "PickAxe"  # Công cụ cần thiết
var required_tier: int = 3  # Cần tier 3 (ví dụ GoldPickAxe hoặc IronPickAxe cao cấp) để đào

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health -= amount
	# Play the hit sound
	$AudioStreamPlayer2D.play()
	if current_health <= 0:
		break_gold_mine()

func break_gold_mine():
	# Tìm node Ground để thêm Gold vào
	var ground_node = get_tree().root.get_node("Ground")
	if ground_node:
		for i in range(3):  # Tạo 2 mảnh quặng vàng (có thể điều chỉnh số lượng)
			var gold_instance = create_gold_item()
			gold_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			ground_node.add_child(gold_instance)
	
	# Tìm spawner và xóa entity (mỏ vàng) khỏi danh sách
	var spawner = find_spawner_for_entity()
	if spawner:
		spawner.remove_entity(self)
	
	queue_free()

func create_gold_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var gold = item_scene.instantiate()
	
	# Gán thuộc tính cho item
	gold.item_name = "Gold"  # Tên item là GoldOre
	return gold

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
