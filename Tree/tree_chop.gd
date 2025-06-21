extends StaticBody2D

@export var max_health: int = 14  # Máu của cây
var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()  # Load item_data

var current_health: int
var required_tool: String = "Axe"  # Công cụ cần thiết
var required_tier: int = 1  # Cần tier 1 (StoneAxe) để chặt

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health -= amount
	# Play the hit sound
	$AudioStreamPlayer2D.play()
	if current_health <= 0:
		die()

func die():
	# Tìm node Ground để thêm TreeLog và Apple vào
	var ground_node = get_tree().root.get_node("/root/Ground")
	if ground_node:
		# Tạo 3 khúc gỗ (TreeLog)
		for i in range(3):
			var log_instance = create_log_item()
			log_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			ground_node.add_child(log_instance)
		
		# 30% khả năng tạo táo (Apple)
		var chance = randf()
		if chance <= 0.3:
			var apple_instance = create_apple_item()
			apple_instance.position = global_position + Vector2(randi_range(-15, 15), randi_range(-15, 15))
			ground_node.add_child(apple_instance)
	
	# Tạo hiệu ứng làm mờ
	var sprite = $Sprite2D
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_on_fade_complete)  # Gọi hàm xử lý sau khi hiệu ứng hoàn tất

func _on_fade_complete():
	# Tìm spawner và xóa entity (cây) khỏi danh sách
	var spawner = find_spawner_for_entity()
	if spawner:
		spawner.remove_entity(self)
	
	queue_free()

func create_log_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var log = item_scene.instantiate()
	
	# Gán thuộc tính cho item
	log.item_name = "TreeLog"
	return log

func create_apple_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var apple = item_scene.instantiate()
	
	# Gán thuộc tính cho item
	apple.item_name = "Apple"
	return apple

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
