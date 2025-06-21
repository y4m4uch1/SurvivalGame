extends Node2D

@onready var world = $World
@onready var cave_world = $CaveWorld
@onready var swamp_world = $SwampWorld
@onready var desert_world = $DesertWorld
@onready var player = $Player
@onready var background_music = $BackgroundMusic
@onready var pause_menu = $PauseMenu
@onready var ground = get_node("/root/Ground")  # Reference to the Ground node

# Danh sách các file nhạc
var music_tracks = [
	preload("res://Main/GameplayMusic1.wav"),
	preload("res://Main/GameplayMusic2.wav"),
	preload("res://Main/GameplayMusic3.wav")
]
var cave_music_tracks = [
	preload("res://World/Cave/CaveMusic1.wav"),
	# preload()  # Thay bằng đường dẫn thực tế
]
var swamp_music_tracks = [
	#preload("res://World/Swamp/SwampMusic1.wav"),
	# Add more swamp music tracks if available
]
var desert_music_tracks = [
	#preload("res://World/Desert/DesertMusic1.wav"),
	# Add more desert music tracks if available
]

# Variable to store the position of the entrances used
var last_cave_entrance_position: Vector2
var last_swamp_entrance_position: Vector2
var last_desert_entrance_position: Vector2
var is_boss_music_playing: bool = false  # Biến để theo dõi trạng thái nhạc boss

# Dictionary to store the original state of nodes
var node_states: Dictionary = {}

# Kích thước bản đồ và tile
const MAP_WIDTH: int = 300
const MAP_HEIGHT: int = 250
const TILE_SIZE: float = 16.0  # Kích thước tile (pixel)

func _ready():
	# Ensure the world is visible and other worlds are hidden at start
	world.visible = true
	world.process_mode = Node.PROCESS_MODE_INHERIT
	if cave_world:
		cave_world.visible = false
		cave_world.process_mode = Node.PROCESS_MODE_DISABLED
		cave_world.clear_tilemap()
	if swamp_world:
		swamp_world.visible = false
		swamp_world.process_mode = Node.PROCESS_MODE_DISABLED
		swamp_world.clear_tilemap()
	if desert_world:
		desert_world.visible = false
		desert_world.process_mode = Node.PROCESS_MODE_DISABLED
		desert_world.clear_tilemap()
	
	last_cave_entrance_position = Vector2(0, 0)
	last_swamp_entrance_position = Vector2(0, 0)
	last_desert_entrance_position = Vector2(0, 0)
	
	if background_music:
		background_music.connect("finished", Callable(self, "_on_music_finished"))
		play_random_music("world")
	
	if Global.is_loading_game:
		if pause_menu:
			pause_menu.load_game()
	else:
		spawn_player_randomly()
	
	if player:
		player.connect("player_died", Callable(self, "_on_player_died"))
	
	player.update_world_references(swamp_world, cave_world, desert_world)

func play_random_music(music_type: String):
	if not background_music or is_boss_music_playing:
		return
	var tracks = []
	match music_type:
		"world":
			tracks = music_tracks
		"cave":
			tracks = cave_music_tracks
		"swamp":
			tracks = swamp_music_tracks
		"desert":
			tracks = desert_music_tracks
	if tracks.size() > 0:
		var random_index = randi() % tracks.size()
		background_music.stream = tracks[random_index]
		background_music.volume_db = -10.0
		background_music.play()

func _on_music_finished():
	if is_boss_music_playing and background_music.stream:
		# Loop boss music if playing
		background_music.play()
	else:
		# Play music based on environment
		if cave_world and cave_world.visible:
			play_random_music("cave")
		elif swamp_world and swamp_world.visible:
			play_random_music("swamp")
		elif desert_world and desert_world.visible:
			play_random_music("desert")
		else:
			play_random_music("world")

func enter_cave(entrance_position: Vector2):
	# Store the entrance position
	last_cave_entrance_position = entrance_position
	
	# Save state of nodes under Ground (except player, UI, and persistent nodes)
	node_states.clear()
	if ground:
		for node in ground.get_children():
			if node == player or node is CanvasLayer or node == background_music or node.name == "MapView":
				continue
			node_states[node] = {
				"visible": node.visible if node.has_method("set_visible") else null,
				"process_mode": node.process_mode,
				"collision_layer": node.collision_layer if node is CollisionObject2D else 0,
				"collision_mask": node.collision_mask if node is CollisionObject2D else 0
			}
			if node.has_method("set_visible"):
				node.visible = false
			if node.has_method("set_process_mode"):
				node.process_mode = Node.PROCESS_MODE_DISABLED
			if node is CollisionObject2D:
				node.collision_layer = 0
				node.collision_mask = 0
	
	# Disable and hide other worlds
	if world:
		world.visible = false
		world.process_mode = Node.PROCESS_MODE_DISABLED
		disable_tilemap_collisions(world)
	if swamp_world:
		swamp_world.visible = false
		swamp_world.process_mode = Node.PROCESS_MODE_DISABLED
		swamp_world.clear_tilemap()
	if desert_world:
		desert_world.visible = false
		desert_world.process_mode = Node.PROCESS_MODE_DISABLED
		desert_world.clear_tilemap()
	
	# Re-instantiate CaveWorld if it doesn't exist
	if not cave_world:
		var cave_scene = preload("res://World/Cave/CaveWorld.tscn")
		cave_world = cave_scene.instantiate()
		add_child(cave_world)
		cave_world.name = "CaveWorld"
	
	# Enable and show the cave
	if cave_world:
		cave_world.process_mode = Node.PROCESS_MODE_INHERIT
		cave_world.visible = true
		cave_world.generate_tilemap()
	
	# Play cave music
	if background_music and not is_boss_music_playing:
		if background_music.playing:
			background_music.stop()
		play_random_music("cave")

	# Move player to a starting position in the cave
	player.position = Vector2(0, 0)
	player.update_world_references(swamp_world, cave_world, desert_world)
	
func exit_cave():
	# Xóa toàn bộ node CaveWorld
	if cave_world:
		cave_world.queue_free()
		cave_world = null
	
	# Restore state of nodes
	if ground:
		for node in ground.get_children():
			if node in node_states:
				if node_states[node]["visible"] != null and node.has_method("set_visible"):
					node.visible = node_states[node]["visible"]
				if node.has_method("set_process_mode"):
					node.process_mode = node_states[node]["process_mode"]
				if node is CollisionObject2D:
					node.collision_layer = node_states[node]["collision_layer"]
					node.collision_mask = node_states[node]["collision_mask"]
	
	# Enable and show the world
	if world:
		world.visible = true
		world.process_mode = Node.PROCESS_MODE_INHERIT
		restore_tilemap_collisions(world)
	# Ensure other worlds remain disabled
	if swamp_world:
		swamp_world.visible = false
		swamp_world.process_mode = Node.PROCESS_MODE_DISABLED
		swamp_world.clear_tilemap()
	if desert_world:
		desert_world.visible = false
		desert_world.process_mode = Node.PROCESS_MODE_DISABLED
		desert_world.clear_tilemap()
	
	# Move player to the last cave entrance position
	player.position = last_cave_entrance_position + Vector2(0, 50)
	
	# Play world music
	if background_music and not is_boss_music_playing:
		if background_music.playing:
			background_music.stop()
		play_random_music("world")
	
	# Clear node states
	node_states.clear()
	player.update_world_references(swamp_world, cave_world, desert_world)
	
func enter_swamp(entrance_position: Vector2):
	# Store the entrance position
	last_swamp_entrance_position = entrance_position
	
	# Save state of nodes under Ground (except player, UI, and persistent nodes)
	node_states.clear()
	if ground:
		for node in ground.get_children():
			if node == player or node is CanvasLayer or node == background_music or node.name == "MapView":
				continue
			node_states[node] = {
				"visible": node.visible if node.has_method("set_visible") else null,
				"process_mode": node.process_mode,
				"collision_layer": node.collision_layer if node is CollisionObject2D else 0,
				"collision_mask": node.collision_mask if node is CollisionObject2D else 0
			}
			if node.has_method("set_visible"):
				node.visible = false
			if node.has_method("set_process_mode"):
				node.process_mode = Node.PROCESS_MODE_DISABLED
			if node is CollisionObject2D:
				node.collision_layer = 0
				node.collision_mask = 0
	
	# Disable and hide other worlds
	if world:
		world.visible = false
		world.process_mode = Node.PROCESS_MODE_DISABLED
		disable_tilemap_collisions(world)
	if cave_world:
		cave_world.visible = false
		cave_world.process_mode = Node.PROCESS_MODE_DISABLED
		cave_world.clear_tilemap()
	if desert_world:
		desert_world.visible = false
		desert_world.process_mode = Node.PROCESS_MODE_DISABLED
		desert_world.clear_tilemap()
	
	# Re-instantiate SwampWorld if it doesn't exist
	if not swamp_world:
		var swamp_scene = preload("res://World/Swamp/SwampWorld.tscn")
		swamp_world = swamp_scene.instantiate()
		add_child(swamp_world)
		swamp_world.name = "SwampWorld"
	
	# Enable and show the swamp
	if swamp_world:
		swamp_world.process_mode = Node.PROCESS_MODE_INHERIT
		swamp_world.visible = true
		swamp_world.generate_tilemap()
	
	# Play swamp music
	if background_music and not is_boss_music_playing:
		if background_music.playing:
			background_music.stop()
		play_random_music("swamp")

	# Move player to a starting position in the swamp
	player.position = Vector2(0, 0)
	player.update_world_references(swamp_world, cave_world, desert_world)
	
func exit_swamp():
	# Xóa toàn bộ node SwampWorld
	if swamp_world:
		swamp_world.queue_free()
		swamp_world = null
	
	# Restore state of nodes
	if ground:
		for node in ground.get_children():
			if node in node_states:
				if node_states[node]["visible"] != null and node.has_method("set_visible"):
					node.visible = node_states[node]["visible"]
				if node.has_method("set_process_mode"):
					node.process_mode = node_states[node]["process_mode"]
				if node is CollisionObject2D:
					node.collision_layer = node_states[node]["collision_layer"]
					node.collision_mask = node_states[node]["collision_mask"]
	
	# Enable and show the world
	if world:
		world.visible = true
		world.process_mode = Node.PROCESS_MODE_INHERIT
		restore_tilemap_collisions(world)
	# Ensure other worlds remain disabled
	if cave_world:
		cave_world.visible = false
		cave_world.process_mode = Node.PROCESS_MODE_DISABLED
		cave_world.clear_tilemap()
	if desert_world:
		desert_world.visible = false
		desert_world.process_mode = Node.PROCESS_MODE_DISABLED
		desert_world.clear_tilemap()
	
	# Move player to the last swamp entrance position
	player.position = last_swamp_entrance_position + Vector2(0, 50)
	
	# Play world music
	if background_music and not is_boss_music_playing:
		if background_music.playing:
			background_music.stop()
		play_random_music("world")
	
	# Clear node states
	node_states.clear()
	player.update_world_references(swamp_world, cave_world, desert_world)
	
func enter_desert(entrance_position: Vector2):
	# Store the entrance position
	last_desert_entrance_position = entrance_position
	
	# Save state of nodes under Ground (except player, UI, and persistent nodes)
	node_states.clear()
	if ground:
		for node in ground.get_children():
			if node == player or node is CanvasLayer or node == background_music or node.name == "MapView":
				continue
			node_states[node] = {
				"visible": node.visible if node.has_method("set_visible") else null,
				"process_mode": node.process_mode,
				"collision_layer": node.collision_layer if node is CollisionObject2D else 0,
				"collision_mask": node.collision_mask if node is CollisionObject2D else 0
			}
			if node.has_method("set_visible"):
				node.visible = false
			if node.has_method("set_process_mode"):
				node.process_mode = Node.PROCESS_MODE_DISABLED
			if node is CollisionObject2D:
				node.collision_layer = 0
				node.collision_mask = 0
	
	# Disable and hide other worlds
	if world:
		world.visible = false
		world.process_mode = Node.PROCESS_MODE_DISABLED
		disable_tilemap_collisions(world)
	if cave_world:
		cave_world.visible = false
		cave_world.process_mode = Node.PROCESS_MODE_DISABLED
		cave_world.clear_tilemap()
	if swamp_world:
		swamp_world.visible = false
		swamp_world.process_mode = Node.PROCESS_MODE_DISABLED
		swamp_world.clear_tilemap()
	
	# Re-instantiate DesertWorld if it doesn't exist
	if not desert_world:
		var desert_scene = preload("res://World/Desert/DesertWorld.tscn")
		desert_world = desert_scene.instantiate()
		add_child(desert_world)
		desert_world.name = "DesertWorld"
	
	# Enable and show the desert
	if desert_world:
		desert_world.process_mode = Node.PROCESS_MODE_INHERIT
		desert_world.visible = true
		desert_world.generate_tilemap()
	
	# Play desert music
	if background_music and not is_boss_music_playing:
		if background_music.playing:
			background_music.stop()
		play_random_music("desert")

	# Move player to a starting position in the desert
	player.position = Vector2(0, 0)
	player.update_world_references(swamp_world, cave_world, desert_world)
	
func exit_desert():
	# Xóa toàn bộ node DesertWorld
	if desert_world:
		desert_world.queue_free()
		desert_world = null
	
	# Restore state of nodes
	if ground:
		for node in ground.get_children():
			if node in node_states:
				if node_states[node]["visible"] != null and node.has_method("set_visible"):
					node.visible = node_states[node]["visible"]
				if node.has_method("set_process_mode"):
					node.process_mode = node_states[node]["process_mode"]
				if node is CollisionObject2D:
					node.collision_layer = node_states[node]["collision_layer"]
					node.collision_mask = node_states[node]["collision_mask"]
	
	# Enable and show the world
	if world:
		world.visible = true
		world.process_mode = Node.PROCESS_MODE_INHERIT
		restore_tilemap_collisions(world)
	# Ensure other worlds remain disabled
	if cave_world:
		cave_world.visible = false
		cave_world.process_mode = Node.PROCESS_MODE_DISABLED
		cave_world.clear_tilemap()
	if swamp_world:
		swamp_world.visible = false
		swamp_world.process_mode = Node.PROCESS_MODE_DISABLED
		swamp_world.clear_tilemap()
	
	# Move player to the last desert entrance position
	player.position = last_desert_entrance_position + Vector2(0, 50)
	
	# Play world music
	if background_music and not is_boss_music_playing:
		if background_music.playing:
			background_music.stop()
		play_random_music("world")
	
	# Clear node states
	node_states.clear()
	player.update_world_references(swamp_world, cave_world, desert_world)
	
func spawn_player_randomly() -> void:
	var attempts: int = 10
	var placed: bool = false
	for i in range(attempts):
		var tile_pos: Vector2 = Vector2(
			randi_range(0, MAP_WIDTH - 1),
			randi_range(0, MAP_HEIGHT - 1)
		)
		var world_pos: Vector2 = tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
		if is_position_free(world_pos):
			player.position = world_pos
			placed = true
			break

func is_position_free(pos: Vector2) -> bool:
	var tile_map = world
	if not tile_map:
		return false
	var tile_pos = tile_map.local_to_map(pos)
	var tile_data = tile_map.get_cell_tile_data(0, tile_pos)
	if tile_data:
		var atlas_coords = tile_map.get_cell_atlas_coords(0, tile_pos)
		if atlas_coords == Vector2i(0, 1):  # Chặn tile nước
			return false
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if not space_state:
		return false
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 20.0
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.transform = Transform2D(0, pos)
	query.shape = shape
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result: Array = space_state.intersect_shape(query)
	return result.is_empty()

func set_boss_music_playing(is_playing: bool):
	is_boss_music_playing = is_playing

func _on_player_died():
	get_tree().change_scene_to_file("res://GUI/YouDie/YouDie.tscn")

func disable_tilemap_collisions(tilemap: TileMap):
	var tileset = tilemap.tile_set
	for layer in range(tileset.get_physics_layers_count()):
		tileset.set_physics_layer_collision_layer(layer, 0)
		tileset.set_physics_layer_collision_mask(layer, 0)

func restore_tilemap_collisions(tilemap: TileMap):
	var tileset = tilemap.tile_set
	# Khôi phục các layer và mask ban đầu (thay đổi giá trị này theo thiết lập của bạn)
	for layer in range(tileset.get_physics_layers_count()):
		tileset.set_physics_layer_collision_layer(layer, 1)  # Giả sử layer 1 là layer va chạm
		tileset.set_physics_layer_collision_mask(layer, 1)
