extends TileMap

# Map size in tiles 
var map_width = 200
var map_height = 200

# Noise for terrain generation
var noise: FastNoiseLite

func _ready():
	pass

func initialize_noise():
	if not noise:
		noise = FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.seed = randi()
		noise.frequency = 0.06

func generate_tilemap():
	initialize_noise()

	# List of possible grass tile atlas coordinates
	var grass_tiles = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(3, 0)
	]

	# Generate tilemap
	for x in range(map_width):
		for y in range(map_height):
			var noise_value = noise.get_noise_2d(x, y)
			var tile_id
			if noise_value > 0.1:
				# Water tiles: 99% Vector2i(4, 0), 1% Vector2i(7, 0)
				if randf() < 0.01: # 1% chance
					tile_id = Vector2i(7, 0)
				else: # 99% chance
					tile_id = Vector2i(4, 0)
			else:
				# Random grass tile
				tile_id = grass_tiles[randi() % grass_tiles.size()]
			set_cell(0, Vector2i(x, y), 0, tile_id)

	# Spawn objects
	var spawners = find_spawners()
	for spawner in spawners:
		if is_instance_valid(spawner):
			spawner.spawn_entities()

func clear_tilemap():
	for x in range(map_width):
		for y in range(map_height):
			set_cell(0, Vector2i(x, y), -1)
	
	var spawners = find_spawners()
	for spawner in spawners:
		if is_instance_valid(spawner):
			spawner.clear_entities()
	
	noise = null

func find_spawners() -> Array:
	var spawners: Array = []
	var script_path = "res://World/Cave/spawn_swamp_obj.gd"
	for node in get_children():
		if node.get_script() and node.get_script().resource_path == script_path:
			spawners.append(node)
	return spawners
