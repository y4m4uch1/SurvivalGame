extends Node2D

# Scene của CaveEntrance (CaveEntrance.tscn)
@export var entity_scene: PackedScene

# Khu vực spawn (giới hạn tọa độ x, y)
@export var spawn_area: Rect2 = Rect2(0, 0, 4800, 4000)

# Bán kính kiểm tra va chạm (điều chỉnh theo kích thước CaveEntrance)
@export var collision_radius: float = 20.0

# Layer va chạm để kiểm tra (điều chỉnh theo layer của bạn)
@export var collision_mask: int = 1

# Bật/tắt kiểm tra TileMap
@export var check_tilemap: bool = true

# Kích thước tile (pixel)
const TILE_SIZE: float = 16.0

# Thời gian hồi sinh (15 phút = 900 giây)
@export var respawn_time: float = 900.0

# Biến để bật/tắt khả năng hồi sinh
@export var can_respawn: bool = true

@onready var tile_map = get_node_or_null("/root/Ground/World")  # Tham chiếu đến TileMap

var spawned_entities: Array = []  # Danh sách để lưu thông tin các CaveEntrance
var respawn_queue: Array = []    # Danh sách các CaveEntrance đang chờ hồi sinh

func _ready() -> void:
	# Không sinh CaveEntrance ngay từ đầu
	pass

# Hàm được gọi khi Unstoppable chết
func on_unstoppable_died() -> void:
	# Tạo một CaveEntrance mới khi Unstoppable chết
	spawn_cave_entrance()

func spawn_cave_entrance() -> void:
	if not entity_scene:
		return
	
	# Tìm vị trí hợp lệ để spawn
	var random_pos = find_valid_spawn_position()
	if random_pos == Vector2.ZERO:
		print("Warning: Could not find valid spawn position for CaveEntrance after attempts!")
		return
	
	# Tạo CaveEntrance mới ở vị trí hợp lệ
	var instance: Node = entity_scene.instantiate()
	instance.position = random_pos
	add_child(instance)
	
	# Lưu thông tin CaveEntrance vào spawned_entities
	var tile_pos = Vector2(floor(random_pos.x / TILE_SIZE), floor(random_pos.y / TILE_SIZE))
	var entity_data = {
		"type": entity_scene.resource_path,
		"tile_position": {"x": tile_pos.x, "y": tile_pos.y},
		"visible": true,
		"name": instance.name,
		"item_name": "",  # Không sử dụng item_name cho CaveEntrance
		"instance": instance,
		"can_respawn": can_respawn
	}
	spawned_entities.append(entity_data)

func find_valid_spawn_position() -> Vector2:
	var attempts: int = 10
	for i in range(attempts):
		var random_pos: Vector2 = Vector2(
			randf_range(spawn_area.position.x, spawn_area.end.x),
			randf_range(spawn_area.position.y, spawn_area.end.y)
		)
		if is_position_free(random_pos):
			return random_pos
	return Vector2.ZERO

func is_position_free(pos: Vector2) -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if not space_state:
		return false
	
	# Kiểm tra va chạm vật lý
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = collision_radius
	
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.transform = Transform2D(0, pos)
	query.shape = shape
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var result: Array = space_state.intersect_shape(query)
	if not result.is_empty():
		return false
	
	# Kiểm tra TileMap (nếu bật)
	if check_tilemap and tile_map:
		var tile_pos = tile_map.local_to_map(pos)
		var tile_data = tile_map.get_cell_tile_data(0, tile_pos)
		if tile_data:
			var atlas_id = tile_map.get_cell_source_id(0, tile_pos)
			if atlas_id == 1:  # Giả sử atlas_id == 1 là tile không thể đặt
				return false
	
	return true

# Hàm được gọi khi CaveEntrance bị xóa (khi người chơi vào hang)
func on_cave_entrance_removed(cave_entrance: Node) -> void:
	remove_entity(cave_entrance)

func remove_entity(entity_instance: Node) -> void:
	for i in range(spawned_entities.size()):
		if spawned_entities[i]["instance"] == entity_instance:
			var entity_data = spawned_entities[i]
			spawned_entities.remove_at(i)
			if entity_data["can_respawn"]:
				start_respawn_timer(entity_data)
			return

func start_respawn_timer(entity_data: Dictionary) -> void:
	var timer = Timer.new()
	timer.wait_time = respawn_time
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_respawn_timer_timeout").bind(entity_data))
	add_child(timer)
	timer.start()
	respawn_queue.append({
		"entity_data": entity_data,
		"timer": timer,
		"start_time": Time.get_unix_time_from_system()
	})

func _on_respawn_timer_timeout(entity_data: Dictionary) -> void:
	# Convert tile_position to world position
	var tile_pos = Vector2(entity_data["tile_position"]["x"], entity_data["tile_position"]["y"])
	var respawn_pos = tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	if not is_position_free(respawn_pos):
		respawn_pos = find_valid_spawn_position()
		if respawn_pos == Vector2.ZERO:
			return
	
	var instance: Node = entity_scene.instantiate()
	instance.position = respawn_pos
	add_child(instance)
	
	var new_tile_pos = Vector2(floor(respawn_pos.x / TILE_SIZE), floor(respawn_pos.y / TILE_SIZE))
	var new_entity_data = {
		"type": entity_data["type"],
		"tile_position": {"x": new_tile_pos.x, "y": new_tile_pos.y},
		"visible": true,
		"name": instance.name,
		"item_name": "",
		"instance": instance,
		"can_respawn": entity_data["can_respawn"]
	}
	spawned_entities.append(new_entity_data)
	
	# Remove from respawn_queue
	for i in range(respawn_queue.size()):
		if respawn_queue[i]["entity_data"] == entity_data:
			respawn_queue.remove_at(i)
			break

func get_spawned_entities() -> Array:
	var entities_data = []
	for entity in spawned_entities:
		entities_data.append({
			"type": entity["type"],
			"tile_position": entity["tile_position"],
			"visible": entity["visible"],
			"name": entity["name"],
			"item_name": entity["item_name"],
			"can_respawn": entity["can_respawn"],
			"instance": entity["instance"]
		})
	return entities_data

func get_respawn_queue() -> Array:
	var queue_data = []
	for item in respawn_queue:
		var time_remaining = item["timer"].time_left
		queue_data.append({
			"entity_data": {
				"type": item["entity_data"]["type"],
				"tile_position": item["entity_data"]["tile_position"],
				"item_name": item["entity_data"]["item_name"],
				"can_respawn": item["entity_data"]["can_respawn"],
				"name": item["entity_data"]["name"]
			},
			"time_remaining": time_remaining
		})
	return queue_data

func restore_respawn_timer(entity_data: Dictionary, time_remaining: float) -> void:
	var timer = Timer.new()
	timer.wait_time = time_remaining
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_respawn_timer_timeout").bind(entity_data))
	add_child(timer)
	timer.start()
	respawn_queue.append({
		"entity_data": entity_data,
		"timer": timer,
		"start_time": Time.get_unix_time_from_system() - (respawn_time - time_remaining)
	})
