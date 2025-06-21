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

	# List of possible desert tile atlas coordinates
	var desert_tiles = [
		Vector2i(10, 6),
		Vector2i(12, 6),
		Vector2i(14, 6),
		Vector2i(15, 10),
		Vector2i(14, 11),		
	]

	# Generate tilemap
	for x in range(map_width):
		for y in range(map_height):
			var noise_value = noise.get_noise_2d(x, y)
			var tile_id
			tile_id = desert_tiles[randi() % desert_tiles.size()]
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
	var script_path = "res://World/Desert/Scripts/spawn_desert_obj.gd"
	for node in get_children():
		if node.get_script() and node.get_script().resource_path == script_path:
			spawners.append(node)
	return spawners
