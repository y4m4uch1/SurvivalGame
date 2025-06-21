extends Node2D

# Scene của trader (Trader.tscn)
@export var entity_scene: PackedScene

# Khu vực spawn (giới hạn tọa độ x, y)
@export var spawn_area: Rect2 = Rect2(0, 0, 4800, 4000)

# Thời gian hồi sinh (10 phút = 600 giây)
@export var respawn_time: float = 600.0

# Bán kính kiểm tra va chạm (điều chỉnh theo kích thước trader)
@export var collision_radius: float = 20.0

# Layer va chạm để kiểm tra (điều chỉnh theo layer của bạn)
@export var collision_mask: int = 1

# Bật/tắt kiểm tra TileMap
@export var check_tilemap: bool = true

@onready var tile_map = get_node_or_null("/root/Ground/World")  # Tham chiếu đến TileMap

var trader_instance: Node = null  # Lưu trader hiện tại
var respawn_timer: Timer = null   # Timer để hồi sinh

func _ready() -> void:
	var world = get_node("/root/Ground/World") # Điều chỉnh đường dẫn nếu cần
	if world:
		world.connect("tilemap_generated", Callable(self, "spawn_trader"))

func spawn_trader() -> void:
	if not entity_scene:
		return
	
	# Nếu đã có trader, xóa nó
	if trader_instance:
		trader_instance.queue_free()
	
	# Tìm vị trí hợp lệ để spawn
	var random_pos = find_valid_spawn_position()
	if random_pos == Vector2.ZERO:
		print("Warning: Could not find valid spawn position for Trader after attempts!")
		return
	
	# Tạo trader mới ở vị trí hợp lệ
	trader_instance = entity_scene.instantiate()
	trader_instance.position = random_pos
	add_child(trader_instance)
	
	# Bắt đầu timer hồi sinh
	start_respawn_timer()

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

func start_respawn_timer() -> void:
	if respawn_timer:
		respawn_timer.queue_free()
	
	respawn_timer = Timer.new()
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.connect("timeout", Callable(self, "_on_respawn_timer_timeout"))
	add_child(respawn_timer)
	respawn_timer.start()

func _on_respawn_timer_timeout() -> void:
	spawn_trader()
