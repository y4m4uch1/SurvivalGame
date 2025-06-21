extends Node2D

# Scene của thực thể (Tree.tscn, Rock.tscn, Item.tscn, v.v.)
@export var entity_scene: PackedScene

# Số lượng thực thể hoặc cụm muốn spawn
@export var spawn_count: int = 5

# Tên item (dành cho Item.tscn, ví dụ: "Rock", "TreeLog")
@export var item_name: String = ""

# Kích thước tile (pixel)
const TILE_SIZE: float = 16.0

# Khu vực spawn (giới hạn tọa độ x, y)
@export var spawn_area: Rect2 = Rect2(0, 0, 4800, 4000)

@onready var tile_map = get_node("/root/Ground/World")

# Bán kính kiểm tra va chạm (điều chỉnh theo kích thước thực thể)
@export var collision_radius: float = 20.0

# Layer va chạm để kiểm tra (điều chỉnh theo layer của bạn)
@export var collision_mask: int = 1

# Spawn theo cụm (dành cho boulder_spawner.gd)
@export var spawn_in_clusters: bool = false
@export var min_entities_per_cluster: int = 1
@export var max_entities_per_cluster: int = 5
@export var cluster_radius: float = 50.0

# Thời gian hồi sinh (15 phút = 900 giây)
@export var respawn_time: float = 900.0

# Biến để bật/tắt khả năng hồi sinh
@export var can_respawn: bool = false

var spawned_entities = []  # Danh sách để lưu thông tin các đối tượng
var respawn_queue = []    # Danh sách các thực thể đang chờ hồi sinh

# Tín hiệu được phát khi việc sinh thực thể hoàn tất
signal entities_spawned

func _ready() -> void:
	var world = get_node("/root/Ground/World") # Điều chỉnh đường dẫn nếu cần
	if world:
		world.connect("tilemap_generated", Callable(self, "spawn_entities"))

func spawn_entities() -> void:
	if not entity_scene:
		return
	
	if spawn_in_clusters:
		for i in range(spawn_count):
			spawn_cluster()
	else:
		for i in range(spawn_count):
			spawn_single_entity()
	
	emit_signal("entities_spawned")

func spawn_single_entity() -> void:
	var attempts: int = 10
	var placed: bool = false
	for j in range(attempts):
		var random_pos: Vector2 = Vector2(
			randf_range(spawn_area.position.x, spawn_area.end.x),
			randf_range(spawn_area.position.y, spawn_area.end.y)
		)
		if is_position_free(random_pos):
			var instance: Node = entity_scene.instantiate()
			instance.position = random_pos
			
			if entity_scene.resource_path == "res://GUI/Inventory/Item.tscn" and item_name != "":
				instance.item_name = item_name
			
			add_child(instance)
			placed = true
			var tile_pos = Vector2(floor(random_pos.x / TILE_SIZE), floor(random_pos.y / TILE_SIZE))  # Convert to tile position
			var entity_data = {
				"type": entity_scene.resource_path,
				"tile_position": {"x": tile_pos.x, "y": tile_pos.y},  # Store tile_position instead
				"visible": true,
				"name": instance.name,
				"item_name": item_name if entity_scene.resource_path == "res://GUI/Inventory/Item.tscn" else "",
				"instance": instance,
				"can_respawn": can_respawn
			}
			spawned_entities.append(entity_data)
			break

func spawn_cluster() -> void:
	var attempts: int = 10
	var cluster_center: Vector2
	var center_placed: bool = false
	for j in range(attempts):
		var center_x: float = randf_range(spawn_area.position.x, spawn_area.end.x)
		var center_y: float = randf_range(spawn_area.position.y, spawn_area.end.y)
		var potential_center: Vector2 = Vector2(center_x, center_y)
		if is_position_free(potential_center):
			cluster_center = potential_center
			center_placed = true
			break
	if not center_placed:
		return
	
	var entities_in_this_cluster: int = randi_range(min_entities_per_cluster, max_entities_per_cluster)
	for i in range(entities_in_this_cluster):
		var placed: bool = false
		for j in range(attempts):
			var angle: float = randf() * 2 * PI
			var distance: float = randf() * cluster_radius
			var offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance
			var entity_pos: Vector2 = cluster_center + offset
			if is_position_free(entity_pos):
				var instance: Node = entity_scene.instantiate()
				instance.position = entity_pos
				
				if entity_scene.resource_path == "res://GUI/Inventory/Item.tscn" and item_name != "":
					instance.item_name = item_name
				
				add_child(instance)
				placed = true
				var tile_pos = Vector2(floor(entity_pos.x / TILE_SIZE), floor(entity_pos.y / TILE_SIZE))  # Convert to tile position
				var entity_data = {
					"type": entity_scene.resource_path,
					"tile_position": {"x": tile_pos.x, "y": tile_pos.y},  # Use tile_position
					"visible": true,
					"name": instance.name,
					"item_name": item_name if entity_scene.resource_path == "res://GUI/Inventory/Item.tscn" else "",
					"instance": instance,
					"can_respawn": can_respawn
				}
				spawned_entities.append(entity_data)
				break

func is_position_free(pos: Vector2) -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if not space_state:
		return false
	
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

	if not tile_map:
		return false
	
	var tile_pos = tile_map.local_to_map(pos)
	var tile_data = tile_map.get_cell_tile_data(0, tile_pos)
	if tile_data:
		var atlas_coords = tile_map.get_cell_atlas_coords(0, tile_pos)
		if atlas_coords == Vector2i(8, 8): # Chặn water tile
			return false
	
	return true

func get_spawned_entities() -> Array:
	var entities_data = []
	for entity in spawned_entities:
		entities_data.append({
			"type": entity["type"],
			"tile_position": entity["tile_position"],  # Use tile_position
			"visible": entity["visible"],
			"name": entity["name"],
			"item_name": entity["item_name"],
			"can_respawn": entity["can_respawn"],
			"instance": entity["instance"]
		})
	return entities_data

func remove_entity(entity_instance: Node) -> void:
	for i in range(spawned_entities.size()):
		if spawned_entities[i]["instance"] == entity_instance:
			var entity_data = spawned_entities[i]
			spawned_entities.remove_at(i)
			# Check if "can_respawn" exists in entity_data, default to false if not
			if entity_data.has("can_respawn") and entity_data["can_respawn"]:
				start_respawn_timer(entity_data)
			return  # Exit after removing the entity

func start_respawn_timer(entity_data: Dictionary) -> void:
	var timer = Timer.new()
	timer.wait_time = respawn_time
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_respawn_timer_timeout").bind(entity_data))
	add_child(timer)
	timer.start()
	# Thêm vào respawn_queue với timestamp
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
		respawn_pos = find_new_respawn_position()
		if respawn_pos == Vector2.ZERO:
			return
	
	var instance: Node = entity_scene.instantiate()
	instance.position = respawn_pos
	
	if entity_data["item_name"] != "":
		instance.item_name = entity_data["item_name"]
	
	add_child(instance)
	var new_tile_pos = Vector2(floor(respawn_pos.x / TILE_SIZE), floor(respawn_pos.y / TILE_SIZE))  # Convert to tile position
	var new_entity_data = {
		"type": entity_data["type"],
		"tile_position": {"x": new_tile_pos.x, "y": new_tile_pos.y},  # Use tile_position
		"visible": true,
		"name": instance.name,
		"item_name": entity_data["item_name"],
		"instance": instance,
		"can_respawn": entity_data["can_respawn"]
	}
	spawned_entities.append(new_entity_data)
	# Remove from respawn_queue
	for i in range(respawn_queue.size()):
		if respawn_queue[i]["entity_data"] == entity_data:
			respawn_queue.remove_at(i)
			break

func find_new_respawn_position() -> Vector2:
	var attempts: int = 10
	for i in range(attempts):
		var random_pos: Vector2 = Vector2(
			randf_range(spawn_area.position.x, spawn_area.end.x),
			randf_range(spawn_area.position.y, spawn_area.end.y)
		)
		if is_position_free(random_pos):
			return random_pos
	return Vector2.ZERO

# Trả về danh sách các thực thể đang chờ hồi sinh để lưu
func get_respawn_queue() -> Array:
	var queue_data = []
	for item in respawn_queue:
		var time_remaining = item["timer"].time_left
		queue_data.append({
			"entity_data": {
				"type": item["entity_data"]["type"],
				"tile_position": item["entity_data"]["tile_position"],  # Use tile_position
				"item_name": item["entity_data"]["item_name"],
				"can_respawn": item["entity_data"]["can_respawn"],
				"name": item["entity_data"]["name"]
			},
			"time_remaining": time_remaining
		})
	return queue_data

# Khôi phục timer từ dữ liệu đã lưu
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
