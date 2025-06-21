extends Node2D

# Scene of the entity to spawn (e.g., Tree.tscn, Rock.tscn, Item.tscn)
@export var entity_scene: PackedScene

# List of specific coordinates to spawn entities (in world coordinates)
@export var spawn_coordinates: Array[Vector2] = []

# Number of entities to spawn randomly (if no specific coordinates are provided)
@export var spawn_count: int = 10

# Item name (for Item.tscn, e.g., "Rock", "TreeLog")
@export var item_name: String = ""

# Spawn area to limit spawning (in world coordinates)
@export var spawn_area: Rect2 = Rect2(0, 0, 3200, 3200) # Khu vực bên trong CollisionShape2D

# Reference to the CaveWorld TileMap
@onready var tile_map = get_parent() # Giả sử script này là con của TileMap trong CaveWorld

# Collision check radius (adjust based on entity size)
@export var collision_radius: float = 20.0

# Collision layer to check (adjust to your layer setup)
@export var collision_mask: int = 1

# Signal emitted when spawning is complete
signal entities_spawned

func _ready() -> void:
	clear_entities() # Xóa các đối tượng cũ khi khởi tạo
	spawn_entities()

func spawn_entities() -> void:
	# Làm mới seed ngẫu nhiên để đảm bảo vị trí khác nhau mỗi lần
	randomize()
	
	if not entity_scene:
		return
	
	# Spawn at specific coordinates if provided
	for pos in spawn_coordinates:
		if spawn_area.has_point(pos):
			if is_position_free(pos):
				spawn_single_entity(pos)
	
	# Spawn additional random entities if spawn_count is specified
	var spawned_count = spawn_coordinates.size() if spawn_coordinates else 0
	var remaining_count = spawn_count - spawned_count
	
	for i in range(remaining_count):
		var pos = get_random_position()
		var attempts = 0
		const MAX_ATTEMPTS = 50
		
		# Keep trying to find a free position
		while not is_position_free(pos) and attempts < MAX_ATTEMPTS:
			pos = get_random_position()
			attempts += 1
		
		if attempts < MAX_ATTEMPTS:
			spawn_single_entity(pos)
	
	emit_signal("entities_spawned")

func spawn_single_entity(pos: Vector2) -> void:
	var instance: Node = entity_scene.instantiate()
	instance.position = pos
	
	# Set item name if spawning an Item.tscn
	if entity_scene.resource_path == "res://GUI/Inventory/Item.tscn" and item_name != "":
		instance.item_name = item_name
	
	add_child(instance)

func is_position_free(pos: Vector2) -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if not space_state:
		return false
	
	# Create a circle shape for collision checking
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = collision_radius
	
	# Set up physics query
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.transform = Transform2D(0, pos)
	query.shape = shape
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	# Check for collisions
	var result: Array = space_state.intersect_shape(query)
	if not result.is_empty():
		return false
	
	# Check if the position is on a valid tile
	if not tile_map or not tile_map is TileMap:
		return false
	
	var tile_pos = tile_map.local_to_map(pos)
	var tile_data = tile_map.get_cell_tile_data(0, tile_pos)
	if tile_data:
		var atlas_coords = tile_map.get_cell_atlas_coords(0, tile_pos)
		if atlas_coords == Vector2i(4, 16): # Lava tile (non-walkable)
			return false
	
	return true

func get_random_position() -> Vector2:
	var x = randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x)
	var y = randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	return Vector2(x, y)

func clear_entities() -> void:
	# Xóa tất cả các node con (các thực thể đã sinh)
	for child in get_children():
		child.queue_free()
