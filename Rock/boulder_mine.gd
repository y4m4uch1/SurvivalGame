extends StaticBody2D

@export var max_health: int = 20  # Máu của tảng đá
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
		break_rock()

func break_rock():
	# Sử dụng WorldManager để lấy thế giới và container
	var world_manager = get_node("/root/WorldManager")
	var world_info = world_manager.get_current_world_and_container()
	var current_world = world_info["world"]
	var other_container = world_info["container"]

	# Tạo các mảnh đá ngay lập tức
	if current_world:
		for i in range(3):
			var rock_instance = create_rock_item()
			rock_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			if other_container:
				other_container.add_child(rock_instance)
			else:
				current_world.add_child(rock_instance)
	else:
		print("Error: No valid world found to spawn rock items!")
	
	var sprite = $Sprite2D
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_on_fade_complete)

func _on_fade_complete():
	# Tìm spawner và xóa entity (tảng đá) khỏi danh sách
	var spawner = find_spawner_for_entity()
	if spawner:
		spawner.remove_entity(self)
	
	queue_free()

func create_rock_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var rock = item_scene.instantiate()
	
	# Gán thuộc tính cho item
	rock.item_name = "Rock"
	return rock

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
