extends TileMap

signal tilemap_generated

# Map size in tiles
var map_width = 300
var map_height = 250

# Noise for terrain generation
var noise: FastNoiseLite

func _ready():
	# Initialize and generate the tilemap
	initialize_noise()
	generate_tilemap()

func initialize_noise():
	# Initialize noise for random generation
	if not noise:
		noise = FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.seed = randi() # Random seed
		noise.frequency = 0.01 # Terrain smoothness (same as cave)

func generate_tilemap():
	# Initialize noise if not already done
	initialize_noise()

	# Clear existing tiles
	clear_tilemap()

	# List of possible grass tile atlas coordinates
	var grass_tiles = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(0, 2)
	]

	# Loop through the tilemap bounds
	for x in range(map_width):
		for y in range(map_height):
			# Get noise value
			var noise_value = noise.get_noise_2d(x, y)
			
			# Decide tile type based on noise
			var tile_id
			if noise_value > 0.26: # Water tile threshold
				tile_id = Vector2i(0, 1) # Water tile (atlas_coords=8:8)
			else:
				# Randomly select a grass tile from the list
				tile_id = grass_tiles[randi() % grass_tiles.size()]
			
			# Place tile at position (x, y)
			set_cell(0, Vector2i(x, y), 0, tile_id) # source_id=0 for both

	# Free the noise resource after generation is complete
	noise = null
	emit_signal("tilemap_generated")
	
func clear_tilemap():
	# Clear all tiles in the tilemap
	for x in range(map_width):
		for y in range(map_height):
			set_cell(0, Vector2i(x, y), -1) # Setting source_id to -1 removes the tile
			
func load_tilemap(tilemap_data: Dictionary):
	# Clear the existing tilemap
	clear_tilemap()
	
	# Restore tiles from saved data
	if "tiles" in tilemap_data:
		for tile in tilemap_data["tiles"]:
			var pos = Vector2i(tile["x"], tile["y"])
			var atlas_coords = Vector2i(tile["atlas_coords"]["x"], tile["atlas_coords"]["y"])
			var source_id = tile["source_id"]
			set_cell(0, pos, source_id, atlas_coords)
