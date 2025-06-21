extends StaticBody2D

@export var max_health: int = 10 
var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()  # Load item_data

var current_health: int


func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health -= amount
	# Play the hit sound
	$AudioStreamPlayer2D.play()
	if current_health <= 0:
		cactus_chop()

func cactus_chop():
	# Tạo các mảnh than ngay lập tức
	var ground_node = get_tree().root.get_node("Ground")
	if ground_node:
		for i in range(3):  # Tạo 3 mảnh than
			var water = create_water_item()
			water.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			ground_node.add_child(water)
	
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

func create_water_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var water = item_scene.instantiate()
	
	# Gán thuộc tính cho item
	water.item_name = "CleanWater"
	return water

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
