extends Node2D

# Scene của thực thể (Tree.tscn, Rock.tscn, Item.tscn, v.v.)
@export var entity_scene: PackedScene

# Số lượng thực thể hoặc cụm muốn spawn
@export var spawn_count: int = 5

# Tên item (dành cho Item.tscn, ví dụ: "Rock", "TreeLog")
@export var item_name: String = ""

# Kích thước bản đồ (theo tiles)
const MAP_WIDTH: int = 300
const MAP_HEIGHT: int = 250
const TILE_SIZE: float = 16.0  # Kích thước tile (pixel)

# Khu vực spawn (giới hạn tọa độ tile x, y)
@export var spawn_area_tiles: Rect2 = Rect2(0, 0, MAP_WIDTH, MAP_HEIGHT)

@onready var tile_map = get_node("/root/Ground/World")

# Bán kính kiểm tra va chạm (điều chỉnh theo kích thước thực thể)
@export var collision_radius: float = 20.0

# Layer va chạm để kiểm tra (điều chỉnh theo layer của bạn)
@export var collision_mask: int = 1

# Spawn theo cụm
@export var spawn_in_clusters: bool = false
@export var min_entities_per_cluster: int = 1
@export var max_entities_per_cluster: int = 5
@export var cluster_radius: float = 50.0  # Bán kính cụm (pixel)

# Thời gian hồi sinh (15 phút = 900 giây)
@export var respawn_time: float = 900.0

# Biến để bật/tắt khả năng hồi sinh
@export var can_respawn: bool = false

# Thời gian delay giữa các lần spawn (giây)
@export var spawn_delay: float = 0.1  # Có thể điều chỉnh trong Inspector

var spawned_entities = []  # Danh sách để lưu thông tin các đối tượng
var respawn_queue = []    # Danh sách các thực thể đang chờ hồi sinh

# Tín hiệu được phát khi việc sinh thực thể hoàn tất
signal entities_spawned

func _ready() -> void:
	var world = get_node("/root/Ground/World")
	if world:
		world.connect("tilemap_generated", Callable(self, "spawn_entities"))

func spawn_entities() -> void:
	if not entity_scene or Global.is_loading_game:
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
	for j in range(attempts):
		var tile_pos: Vector2 = Vector2(
			randi_range(spawn_area_tiles.position.x, spawn_area_tiles.end.x - 1),
			randi_range(spawn_area_tiles.position.y, spawn_area_tiles.end.y - 1)
		)
		var world_pos: Vector2 = tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
		if is_position_free(world_pos):
			var instance: Node = entity_scene.instantiate()
			instance.position = world_pos
			
			if entity_scene.resource_path == "res://GUI/Inventory/Item.tscn" and item_name != "":
				instance.item_name = item_name
			
			add_child(instance)
			var entity_data = {
				"type": entity_scene.resource_path,
				"tile_position": {"x": tile_pos.x, "y": tile_pos.y},
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
	var cluster_center_tile: Vector2
	var center_placed: bool = false
	for j in range(attempts):
		var center_tile_x: float = randi_range(spawn_area_tiles.position.x, spawn_area_tiles.end.x - 1)
		var center_tile_y: float = randi_range(spawn_area_tiles.position.y, spawn_area_tiles.end.y - 1)
		cluster_center_tile = Vector2(center_tile_x, center_tile_y)
		var center_world_pos: Vector2 = cluster_center_tile * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
		if is_position_free(center_world_pos):
			center_placed = true
			break
	if not center_placed:
		return
	
	var entities_in_this_cluster: int = randi_range(min_entities_per_cluster, max_entities_per_cluster)
	for i in range(entities_in_this_cluster):
		for j in range(attempts):
			var angle: float = randf() * 2 * PI
			var distance: float = randf() * cluster_radius
			var offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance
			var entity_world_pos: Vector2 = (cluster_center_tile * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)) + offset
			var entity_tile_pos: Vector2 = Vector2(
				entity_world_pos.x / TILE_SIZE,
				entity_world_pos.y / TILE_SIZE
			)
			if not spawn_area_tiles.has_point(entity_tile_pos):
				continue
			if is_position_free(entity_world_pos):
				var instance: Node = entity_scene.instantiate()
				instance.position = entity_world_pos
				
				if entity_scene.resource_path == "res://GUI/Inventory/Item.tscn" and item_name != "":
					instance.item_name = item_name
				
				add_child(instance)
				var entity_data = {
					"type": entity_scene.resource_path,
					"tile_position": {"x": entity_tile_pos.x, "y": entity_tile_pos.y},
					"visible": true,
					"name": instance.name,
					"item_name": item_name if entity_scene.resource_path == "res://GUI/Inventory/Item.tscn" else "",
					"instance": instance,
					"can_respawn": can_respawn
				}
				spawned_entities.append(entity_data)
				break
				
func is_position_free(pos: Vector2, entity_scene: PackedScene = self.entity_scene) -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if not space_state:
		return false

	# Lấy CollisionShape2D hoặc Area2D từ mẫu thực thể
	var instance = entity_scene.instantiate()
	var shape: Shape2D = null
	var shape_owner: Node = null

	# Kiểm tra StaticBody2D
	for child in instance.get_children():
		if child is StaticBody2D or child is CharacterBody2D:
			for grand_child in child.get_children():
				if grand_child is CollisionShape2D and not grand_child.disabled:
					shape = grand_child.shape
					shape_owner = grand_child
					break
		elif child is Area2D:
			for grand_child in child.get_children():
				if grand_child is CollisionShape2D and not grand_child.disabled:
					shape = grand_child.shape
					shape_owner = grand_child
					break
		if shape:
			break

	# Nếu không tìm thấy shape, sử dụng CircleShape2D mặc định
	if not shape:
		shape = CircleShape2D.new()
		shape.radius = collision_radius

	# Tạo query kiểm tra va chạm
	var query = PhysicsShapeQueryParameters2D.new()
	query.transform = Transform2D(0, pos)
	query.shape = shape
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = true

	# Kiểm tra va chạm với các đối tượng khác
	var result = space_state.intersect_shape(query, 1) # Giới hạn 1 kết quả để tối ưu
	instance.queue_free() # Giải phóng instance tạm thời

	if not result.is_empty():
		return false

	# Kiểm tra tile nước
	if tile_map:
		var tile_pos = tile_map.local_to_map(pos)
		var tile_data = tile_map.get_cell_tile_data(0, tile_pos)
		if tile_data:
			var atlas_coords = tile_map.get_cell_atlas_coords(0, tile_pos)
			if atlas_coords == Vector2i(0, 1): # Chặn water tile
				return false

	return true

func get_spawned_entities() -> Array:
	var entities_data = []
	for entity in spawned_entities:
		var instance = entity["instance"]
		if instance and is_instance_valid(instance):
			# Cập nhật tile_position từ global_position
			var tile_pos = Vector2(
				instance.global_position.x / TILE_SIZE,
				instance.global_position.y / TILE_SIZE
			)
			entities_data.append({
				"type": entity["type"],
				"tile_position": {"x": tile_pos.x, "y": tile_pos.y},
				"visible": entity["visible"],
				"name": entity["name"],
				"item_name": entity["item_name"],
				"can_respawn": entity["can_respawn"],
				"instance": instance
			})
	return entities_data

func remove_entity(entity_instance: Node) -> void:
	for i in range(spawned_entities.size()):
		if spawned_entities[i]["instance"] == entity_instance:
			var entity_data = spawned_entities[i]
			spawned_entities.remove_at(i)
			if entity_data.has("can_respawn") and entity_data["can_respawn"]:
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
	var tile_pos = Vector2(entity_data["tile_position"]["x"], entity_data["tile_position"]["y"])
	var world_pos = tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	if not is_position_free(world_pos):
		world_pos = find_new_respawn_position()
		if world_pos == Vector2.ZERO:
			return
	
	var instance: Node = entity_scene.instantiate()
	instance.position = world_pos
	var new_tile_pos = Vector2(
		world_pos.x / TILE_SIZE,
		world_pos.y / TILE_SIZE
	)
	
	if entity_data["item_name"] != "":
		instance.item_name = entity_data["item_name"]
	
	add_child(instance)
	var new_entity_data = {
		"type": entity_data["type"],
		"tile_position": {"x": new_tile_pos.x, "y": new_tile_pos.y},
		"visible": true,
		"name": instance.name,
		"item_name": entity_data["item_name"],
		"instance": instance,
		"can_respawn": entity_data["can_respawn"]
	}
	spawned_entities.append(new_entity_data)
	for i in range(respawn_queue.size()):
		if respawn_queue[i]["entity_data"] == entity_data:
			respawn_queue.remove_at(i)
			break

func find_new_respawn_position() -> Vector2:
	var attempts: int = 10
	for i in range(attempts):
		var tile_pos: Vector2 = Vector2(
			randi_range(spawn_area_tiles.position.x, spawn_area_tiles.end.x - 1),
			randi_range(spawn_area_tiles.position.y, spawn_area_tiles.end.y - 1)
		)
		var world_pos: Vector2 = tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
		if is_position_free(world_pos):
			return world_pos
	return Vector2.ZERO

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
