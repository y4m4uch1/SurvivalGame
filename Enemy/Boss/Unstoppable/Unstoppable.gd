extends CharacterBody2D

signal died # Tín hiệu được phát ra khi boss chết

@export var max_health: int = 2000
@export var attack_damage: int = 40
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 3
@export var move_speed: float = 25.0

var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()
@onready var player = get_tree().root.get_node("Ground/Player")
@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar
@onready var roar_sound = $Roar  # Reference to roar sound player
@onready var walk_sound = $Walk  # Reference to walk sound player
@onready var theme_sound = $Theme  # Reference to theme music player

var music_tracks = [
	"res://World/Enemy/Boss/Unstoppable/UnstoppableMusic1.wav",
	"res://World/Enemy/Boss/Unstoppable/UnstoppableMusic2.wav"
]

var current_health: int
var last_attack_time: float = 0.0
var attack_circle: Polygon2D
var is_attacking: bool = false

var move_animation_timer: float = 0.0
var move_animation_speed: float = 0.2
var current_move_frame: int = 0
var attack_animation_timer: float = 0.0
var attack_animation_speed: float = 0.15
var current_attack_frame: int = 0
var walk_sound_timer: float = 0.0  # Timer for walk sound
var walk_sound_interval: float = 0.5  # Interval for walk sound, matching player's footstep_interval

func _ready():
	current_health = max_health
	if not player:
		print("Warning: Player node not found!")
	
	# Configure sprite
	sprite.vframes = 20
	sprite.hframes = 1
	sprite.frame = 0
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false
		health_bar.modulate = Color(1, 0, 0)
	
	# Initialize sound players
	if walk_sound:
		walk_sound.stop()  # Ensure walk sound is off initially
	if roar_sound:
		roar_sound.stop()  # Ensure roar sound is off initially
	if theme_sound:
		theme_sound.stop()  # Ensure theme music is off initially
		# Play random music track
		var random_track = music_tracks[randi() % music_tracks.size()]
		var audio_stream = load(random_track)
		if audio_stream:
			theme_sound.stream = audio_stream
			theme_sound.play()
		else:
			print("Warning: Failed to load music track: ", random_track)

func _physics_process(delta: float):
	if not player:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Move towards player if not attacking
	if not is_attacking:
		move_towards_player(delta)
		update_move_animation(delta)
		# Play walk sound when moving, similar to player's footstep logic
		if velocity != Vector2.ZERO:
			walk_sound_timer += delta
			if walk_sound_timer >= walk_sound_interval and walk_sound and not walk_sound.playing:
				walk_sound.play()
				walk_sound_timer = 0.0
		else:
			walk_sound_timer = walk_sound_interval  # Reset timer when not moving
			if walk_sound and walk_sound.playing:
				walk_sound.stop()
	else:
		update_attack_animation(delta)
		# Stop walk sound during attack
		if walk_sound and walk_sound.playing:
			walk_sound.stop()
	
	# Perform attack if in range and cooldown is over
	if global_position.distance_to(player.global_position) <= attack_range and current_time - last_attack_time >= attack_cooldown:
		attack()
		last_attack_time = current_time
	
	# Move without collision handling
	global_position += velocity * delta

func update_move_animation(delta: float):
	# Update move animation frames
	move_animation_timer += delta
	if move_animation_timer >= move_animation_speed:
		current_move_frame = (current_move_frame + 1) % 6
		sprite.frame = current_move_frame
		move_animation_timer = 0.0
	
	# Flip sprite based on movement direction
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

func update_attack_animation(delta: float):
	# Update attack animation frames
	attack_animation_timer += delta
	if attack_animation_timer >= attack_animation_speed:
		current_attack_frame = (current_attack_frame + 1) % 20
		sprite.frame = 11 + current_attack_frame
		attack_animation_timer = 0.0

func move_towards_player(delta: float):
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed

func take_damage(amount: int):
	current_health -= amount
	if health_bar:
		health_bar.value = current_health
	if current_health <= 0:
		die()

func die():
	emit_signal("died")
	var ground_node = get_tree().root.get_node("Ground")
	if ground_node:
		var gel_chance = randf()
		if gel_chance <= 0.5:
			var gel_instance = create_undefeated_gel_item()
			gel_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			ground_node.add_child(gel_instance)
		
		# Drop 30-50 coins
		var coin_count = randi_range(30, 50)
		for i in range(coin_count):
			var coin_instance = create_coin_item()
			coin_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			ground_node.add_child(coin_instance)
	
		# Tìm và thông báo cho CaveEntranceRespawn
	var cave_entrance_spawner = get_tree().root.get_node("Ground/World/CaveEntrance")  # Điều chỉnh path nếu cần
	if cave_entrance_spawner and cave_entrance_spawner.has_method("on_unstoppable_died"):
		cave_entrance_spawner.on_unstoppable_died()
	
	var spawner = find_spawner_for_entity()
	if spawner:
		spawner.remove_entity(self)
	
	queue_free()

func create_undefeated_gel_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var gel = item_scene.instantiate()
	gel.item_name = "UndefeatedGel"
	return gel

func create_coin_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var coin = item_scene.instantiate()
	coin.item_name = "Coin"
	return coin

func attack():
	is_attacking = true
	velocity = Vector2.ZERO
	current_attack_frame = 0
	attack_animation_timer = 0.0
	
	# Play roar sound, similar to player's attack sound
	if roar_sound and not roar_sound.playing:
		roar_sound.play()
	
	# Create cone-shaped attack visualization
	var cone = Polygon2D.new()
	cone.color = Color(1, 0, 0, 0.3)
	cone.visible = true
	add_child(cone)
	
	# Define cone parameters
	var cone_angle = deg_to_rad(60)  # 60-degree cone
	var cone_radius = attack_range * 2  # Extend range for cone
	var direction = (player.global_position - global_position).normalized()
	var center_angle = atan2(direction.y, direction.x)
	
	# Generate cone points
	var points = []
	var num_points = 32
	points.append(Vector2.ZERO)  # Start at boss position
	for i in range(num_points + 1):
		var angle = center_angle - cone_angle / 2 + (cone_angle * i / num_points)
		var point = Vector2(cos(angle), sin(angle)) * cone_radius
		points.append(point)
	cone.polygon = points
	
	# Create tween for attack effect
	var tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func():
		cone.color = Color(1, 0, 0, 0.8)
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsShapeQueryParameters2D.new()
		var cone_shape = ConvexPolygonShape2D.new()
		var shape_points = []
		shape_points.append(Vector2.ZERO)
		for i in range(num_points + 1):
			var angle = center_angle - cone_angle / 2 + (cone_angle * i / num_points)
			var point = Vector2(cos(angle), sin(angle)) * cone_radius
			shape_points.append(point)
		cone_shape.points = shape_points
		query.shape = cone_shape
		query.transform = Transform2D(0, global_position)
		query.collision_mask = 1
		
		var results = space_state.intersect_shape(query)
		for result in results:
			if result.collider == player and player.has_method("take_damage"):
				player.take_damage(attack_damage)
				print("Undefeated attacked player with cone for " + str(attack_damage) + " damage!")
				break
	)
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		cone.queue_free()
		is_attacking = false
		current_move_frame = 0
		move_animation_timer = 0.0
	)

func update_circle_radius(radius: float):
	draw_circle_points(attack_circle, radius)

func draw_circle_points(polygon: Polygon2D, radius: float):
	var points = []
	var num_points = 32
	for i in range(num_points + 1):
		var angle = i * 2 * PI / num_points
		var point = Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	polygon.polygon = points

func find_spawner_for_entity() -> Node:
	var root = get_tree().root
	var spawners = []
	find_spawners_recursive(root, spawners)
	for spawner in spawners:
		for entity_data in spawner.spawned_entities:
			if entity_data["instance"] == self:
				return spawner
	return null

func find_spawners_recursive(node: Node, spawners: Array) -> void:
	if node.get_script() and node.get_script().resource_path == "res://World/Enemy/Slime/slime_spawner.gd":
		spawners.append(node)
	for child in node.get_children():
		find_spawners_recursive(child, spawners)
