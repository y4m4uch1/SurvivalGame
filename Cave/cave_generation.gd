extends TileMap

# Map size in tiles
var map_width = 200
var map_height = 200
# Room parameters
var min_room_size = 20
var max_room_size = 40
var num_rooms = 25
# Noise for terrain variation
var noise: FastNoiseLite
# Lighting variables
var gradient_texture: GradientTexture2D
var lights: Array = []
const MAX_LIGHTS = 100
# Tile IDs
const GLOWING_TILE = Vector2i(0, 19) # Tile phát sáng
const FLOOR_TILE = Vector2i(7, 14)   # Đường đi và sàn phòng
const WALL_TILE = Vector2i(4, 16)    # Tường

func _ready():
	# Initialize gradient texture and noise
	initialize_gradient_texture()
	initialize_noise()
	generate_tilemap()

func initialize_noise():
	if not noise:
		noise = FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.seed = randi()
		noise.frequency = 0.1

func initialize_gradient_texture():
	# Create a single GradientTexture2D for all lights
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1)) # Trung tâm: trắng sáng
	gradient.set_color(1, Color(1, 1, 1, 0)) # Rìa: trong suốt
	gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 64
	gradient_texture.height = 64
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.fill_from = Vector2(0.5, 0.5)
	gradient_texture.fill_to = Vector2(1, 1)

func generate_tilemap():
	clear_tilemap()

	# Fill map with walls
	for x in range(map_width):
		for y in range(map_height):
			set_cell(0, Vector2i(x, y), 0, WALL_TILE)

	# Generate fixed room at (0, 0)
	var fixed_room = Rect2i(0, 0, min_room_size, min_room_size)
	create_room(fixed_room)
	var rooms = [fixed_room]

	# Generate remaining rooms
	for i in range(num_rooms - 1): # Subtract 1 because we already added the fixed room
		var room_width = randi_range(min_room_size, max_room_size)
		var room_height = randi_range(min_room_size, max_room_size)
		var x = randi_range(2, map_width - room_width - 2)
		var y = randi_range(2, map_height - room_height - 2)

		var new_room = Rect2i(x, y, room_width, room_height)
		var valid = true
		for room in rooms:
			if new_room.intersects(room.grow(3)):
				valid = false
				break
		if valid:
			rooms.append(new_room)
			create_room(new_room)

	# Connect rooms with corridors
	for i in range(rooms.size() - 1):
		var room_a = rooms[i]
		var room_b = rooms[i + 1]
		connect_rooms(room_a, room_b)

	# Collect all glowing tiles (0, 19) and generate cluster lights
	var lava_tiles: Array = []
	for x in range(map_width):
		for y in range(map_height):
			var coords = get_cell_atlas_coords(0, Vector2i(x, y))
			if coords == GLOWING_TILE:
				lava_tiles.append(Vector2i(x, y))
	generate_cluster_lights(lava_tiles)

	# Spawn objects
	var spawners = find_spawners()
	for spawner in spawners:
		if is_instance_valid(spawner):
			spawner.spawn_entities()

func create_room(room: Rect2i):
	# Carve out room with floor tiles, 1% chance for glowing tile
	if not noise:
		initialize_noise() # Ensure noise is initialized
	for x in range(room.position.x, room.position.x + room.size.x):
		for y in range(room.position.y, room.position.y + room.size.y):
			var rand_value = randf()
			var tile = GLOWING_TILE if rand_value < 0.01 else FLOOR_TILE # 1% glowing, 99% floor
			set_cell(0, Vector2i(x, y), 0, tile)

func connect_rooms(room_a: Rect2i, room_b: Rect2i):
	# Get random points in each room
	var point_a = Vector2i(
		randi_range(room_a.position.x, room_a.position.x + room_a.size.x - 1),
		randi_range(room_a.position.y, room_a.position.y + room_a.size.y - 1)
	)
	var point_b = Vector2i(
		randi_range(room_b.position.x, room_b.position.x + room_b.size.x - 1),
		randi_range(room_b.position.y, room_b.position.y + room_b.size.y - 1)
	)

	# Create L-shaped corridor with 3-pixel width
	var x_first = randi() % 2 == 0
	if x_first:
		# Horizontal segment
		for x in range(min(point_a.x, point_b.x), max(point_a.x, point_b.x) + 1):
			for offset_y in range(-1, 2): # 3 pixels wide
				var rand_value = randf()
				var tile = GLOWING_TILE if rand_value < 0.01 else FLOOR_TILE # 1% glowing, 99% floor
				set_cell(0, Vector2i(x, point_a.y + offset_y), 0, tile)
		# Vertical segment
		for y in range(min(point_a.y, point_b.y), max(point_a.y, point_b.y) + 1):
			for offset_x in range(-1, 2): # 3 pixels wide
				var rand_value = randf()
				var tile = GLOWING_TILE if rand_value < 0.01 else FLOOR_TILE # 1% glowing, 99% floor
				set_cell(0, Vector2i(point_b.x + offset_x, y), 0, tile)
	else:
		# Vertical segment
		for y in range(min(point_a.y, point_b.y), max(point_a.y, point_b.y) + 1):
			for offset_x in range(-1, 2): # 3 pixels wide
				var rand_value = randf()
				var tile = GLOWING_TILE if rand_value < 0.01 else FLOOR_TILE # 1% glowing, 99% floor
				set_cell(0, Vector2i(point_a.x + offset_x, y), 0, tile)
		# Horizontal segment
		for x in range(min(point_a.x, point_b.x), max(point_a.x, point_b.x) + 1):
			for offset_y in range(-1, 2): # 3 pixels wide
				var rand_value = randf()
				var tile = GLOWING_TILE if rand_value < 0.01 else FLOOR_TILE # 1% glowing, 99% floor
				set_cell(0, Vector2i(x, point_b.y + offset_y), 0, tile)

func generate_cluster_lights(lava_tiles: Array):
	# Group lava tiles into clusters
	var clusters: Array = []
	var visited: Dictionary = {}

	for tile in lava_tiles:
		var tile_key = vector2i_to_key(tile)
		if tile_key in visited:
			continue
		var cluster = find_cluster(tile, lava_tiles, visited)
		if not cluster.is_empty():
			clusters.append(cluster)

	# Add lights for each cluster
	var light_count = 0
	for cluster in clusters:
		if light_count >= MAX_LIGHTS:
			break
		add_cluster_light(cluster)
		light_count += 1

func add_cluster_light(cluster: Array):
	if cluster.is_empty():
		return

	# Calculate cluster center and size
	var sum_pos = Vector2.ZERO
	for tile in cluster:
		sum_pos += Vector2(tile.x, tile.y)
	var center = sum_pos / cluster.size()
	var pixel_pos = map_to_local(Vector2i(round(center.x), round(center.y)))

	# Estimate cluster size (approximate radius in tiles)
	var max_dist = 0.0
	for tile in cluster:
		var dist = center.distance_to(Vector2(tile.x, tile.y))
		max_dist = max(max_dist, dist)
	var cluster_radius = max_dist * 16.0 # Convert tiles to pixels

	# Create PointLight2D
	var light = PointLight2D.new()
	light.energy = clamp(1.0 + cluster_radius / 32.0, 1.0, 3.0) # Scale energy with size
	light.texture_scale = clamp(cluster_radius / 32.0, 1.5, 5.0) # Scale size
	light.range_layer_min = -1
	light.range_layer_max = 1
	light.color = Color(1.0, 0.5, 0.2, 1.0)
	light.z_index = 1
	light.texture = gradient_texture
	light.position = pixel_pos

	# Add subtle flickering effect
	var tween = create_tween().set_loops()
	tween.tween_property(light, "energy", light.energy * 0.9, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(light, "energy", light.energy, 0.5).set_trans(Tween.TRANS_SINE)

	add_child(light)
	lights.append(light)

func find_cluster(start_tile: Vector2i, lava_tiles: Array, visited: Dictionary) -> Array:
	var cluster: Array = []
	var queue: Array = [start_tile]
	var tile_key = vector2i_to_key(start_tile)
	visited[tile_key] = true

	while not queue.is_empty():
		var current = queue.pop_front()
		cluster.append(current)

		# Check all 4 adjacent tiles
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if abs(dx) + abs(dy) != 1: # Only check cardinal directions
					continue
				var neighbor = Vector2i(current.x + dx, current.y + dy)
				var neighbor_key = vector2i_to_key(neighbor)
				if (neighbor_key in visited or
					neighbor.x < 0 or neighbor.x >= map_width or
					neighbor.y < 0 or neighbor.y >= map_height):
					continue
				if neighbor in lava_tiles:
					visited[neighbor_key] = true
					queue.append(neighbor)
	return cluster

func vector2i_to_key(vec: Vector2i) -> String:
	return str(vec.x) + "," + str(vec.y)

func clear_tilemap():
	for x in range(map_width):
		for y in range(map_height):
			set_cell(0, Vector2i(x, y), -1)
	
	var spawners = find_spawners()
	for spawner in spawners:
		if is_instance_valid(spawner):
			spawner.clear_entities()
	
	clear_lights()
	noise = null

func clear_lights():
	for light in lights:
		if is_instance_valid(light):
			light.queue_free()
	lights.clear()

func find_spawners() -> Array:
	var spawners: Array = []
	var script_path = "res://World/Cave/spawn_cave_obj.gd"
	for node in get_children():
		if node.get_script() and node.get_script().resource_path == script_path:
			spawners.append(node)
	return spawners
