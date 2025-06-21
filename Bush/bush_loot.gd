extends StaticBody2D

@export var max_health: int = 1  # Máu tối đa của bụi cây (không còn dùng nữa)
var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()  # Load dữ liệu item
var player_in_range: bool = false  # Biến kiểm tra player có trong phạm vi không

# Tham chiếu đến Area2D để phát hiện player
var detection_area: Area2D

func _ready():
	# Không cần current_health nữa vì không dùng take_damage
	# current_health = max_health
	
	# Tạo Area2D để phát hiện player nếu chưa có trong scene
	if not has_node("DetectionArea"):
		detection_area = Area2D.new()
		var collision_shape = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 20  # Phạm vi phát hiện (có thể điều chỉnh)
		collision_shape.shape = circle_shape
		detection_area.add_child(collision_shape)
		detection_area.name = "DetectionArea"
		add_child(detection_area)
	else:
		detection_area = $DetectionArea
	
	# Kết nối signals cho Area2D
	detection_area.connect("body_entered", Callable(self, "_on_body_entered"))
	detection_area.connect("body_exited", Callable(self, "_on_body_exited"))

func _input(event):
	# Phá bụi cây trực tiếp khi nhấn E và player trong phạm vi
	if event.is_action_pressed("ui_interact") and player_in_range:
		break_bush()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func break_bush():
	# Tìm node Ground để thêm Fiber
	var ground_node = get_tree().root.get_node("Ground")
	if ground_node:
		for i in range(1):  # Tạo 1 Fiber
			var fiber_instance = create_fiber_item()
			fiber_instance.position = global_position + Vector2(randi_range(-5, 5), randi_range(-5, 5))
			ground_node.add_child(fiber_instance)
	
	# Tìm spawner và xóa bụi cây khỏi danh sách (nếu có)
	var spawner = find_spawner_for_entity()
	if spawner:
		spawner.remove_entity(self)
	
	queue_free()  # Xóa bụi cây

func create_fiber_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var fiber = item_scene.instantiate()
	fiber.item_name = "Fiber"
	return fiber

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
