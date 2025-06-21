extends StaticBody2D

@export var max_health: int = 25  # Máu của mỏ than, tăng nhẹ so với boulder
var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()  # Load item_data

var current_health: int
var required_tool: String = "PickAxe"  # Công cụ cần thiết
var required_tier: int = 1  # Cần tier 1 (StonePickAxe) để đào

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health -= amount
	# Play the hit sound
	$AudioStreamPlayer2D.play()
	if current_health <= 0:
		break_coal()

func break_coal():
	# Tạo các mảnh than ngay lập tức
	var ground_node = get_tree().root.get_node("Ground")
	if ground_node:
		for i in range(3):  # Tạo 3 mảnh than
			var coal_instance = create_coal_item()
			coal_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			ground_node.add_child(coal_instance)
	
	# Tạo hiệu ứng làm mờ
	var sprite = $Sprite2D
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_on_fade_complete)  # Gọi hàm xử lý sau khi hiệu ứng hoàn tất

func _on_fade_complete():
	# Tìm spawner và xóa entity (mỏ than) khỏi danh sách
	var spawner = find_spawner_for_entity()
	if spawner:
		spawner.remove_entity(self)
	
	queue_free()

func create_coal_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var coal = item_scene.instantiate()
	
	# Gán thuộc tính cho item
	coal.item_name = "Coal"
	return coal

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
