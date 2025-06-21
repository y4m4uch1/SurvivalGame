extends CharacterBody2D

signal died # Tín hiệu được phát ra khi boss chết

@export var max_health: int = 2000
@export var attack_damage: int = 40
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 3
@export var move_speed: float = 25.0

var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()
@onready var player = get_tree().root.get_node("Ground/Player")
@onready var sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar
@onready var roar_sound = $Roar  # Reference to roar sound player
@onready var walk_sound = $Walk  # Reference to walk sound player
@onready var theme = $Theme  # Reference to theme music player
@onready var collision_shape = $CollisionShape2D
@onready var attack_area = $AttackArea  # Reference to AttackArea
@onready var detection_area = $Area2D  # Reference to Area2D for detection

var music_tracks = [
	"res://World/Enemy/Boss/Unstoppable/UnstoppableMusic1.wav",
	"res://World/Enemy/Boss/Unstoppable/UnstoppableMusic2.wav"
]

var current_health: int
var last_attack_time: float = 0.0
var attack_circle: Polygon2D
var is_attacking: bool = false
var attack_type: String = "attack1"
var player_in_attack_range: bool = false
var player_in_detection_range: bool = false  # Track if player is in Area2D

var walk_sound_timer: float = 0.0
var walk_sound_interval: float = 0.5

func _ready():
	current_health = max_health
	if not player:
		print("Warning: Player node not found!")
	
	if sprite:
		sprite.play("walk")
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false
		health_bar.modulate = Color(1, 0, 0)
	
	if walk_sound:
		walk_sound.stop()
	if roar_sound:
		roar_sound.stop()
	if theme:
		theme.stop()
		var random_track = music_tracks[randi() % music_tracks.size()]
		var audio_stream = load(random_track)
		if audio_stream:
			theme.stream = audio_stream
			theme.play()
		else:
			print("Warning: Failed to load music track: ", random_track)
	
	# Connect signals for AttackArea
	if attack_area:
		if not attack_area.is_connected("body_entered", Callable(self, "_on_attack_area_body_entered")):
			attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))
		if not attack_area.is_connected("body_exited", Callable(self, "_on_attack_area_body_exited")):
			attack_area.connect("body_exited", Callable(self, "_on_attack_area_body_exited"))
	
	# Connect signals for Area2D (detection area)
	if detection_area:
		if not detection_area.is_connected("body_entered", Callable(self, "_on_detection_area_body_entered")):
			detection_area.connect("body_entered", Callable(self, "_on_detection_area_body_entered"))
		if not detection_area.is_connected("body_exited", Callable(self, "_on_detection_area_body_exited")):
			detection_area.connect("body_exited", Callable(self, "_on_detection_area_body_exited"))

func _physics_process(delta: float):
	if not player:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# If player is in detection range, stop movement and play idle animation
	if player_in_detection_range:
		velocity = Vector2.ZERO
		if sprite and sprite.animation != "attack1" and sprite.animation != "attack2":
			sprite.play("idle")
		if walk_sound and walk_sound.playing:
			walk_sound.stop()
	else:
		# Perform raycast to check for player with dynamic distance
		var player_detected = false
		if not is_attacking:
			var space_state = get_world_2d().direct_space_state
			var direction = (player.global_position - global_position).normalized()
			
			# Calculate y-coordinate difference
			var delta_y = abs(player.global_position.y - global_position.y)
			# Linearly interpolate raycast distance from 10 to 46 based on delta_y
			var max_delta_y = 60.0  # Y difference at which raycast distance reaches 46
			var raycast_distance = lerp(10.0, 46.0, clamp(delta_y / max_delta_y, 0.0, 1.0))
			
			var query = PhysicsRayQueryParameters2D.create(
				global_position,
				global_position + direction * raycast_distance,
				1  # Assuming player is on collision layer 1
			)
			query.exclude = [self]  # Exclude the boss itself
			var result = space_state.intersect_ray(query)
			
			if result and result.collider == player:
				player_detected = true
		
		# Handle movement and animation
		if not is_attacking and not player_detected:
			move_towards_player(delta)
			if sprite and sprite.animation != "walk":
				sprite.play("walk")
			if velocity != Vector2.ZERO:
				walk_sound_timer += delta
				if walk_sound_timer >= walk_sound_interval and walk_sound and not walk_sound.playing:
					walk_sound.play()
					walk_sound_timer = 0.0
			else:
				walk_sound_timer = walk_sound_interval
				if walk_sound and walk_sound.playing:
					walk_sound.stop()
		else:
			velocity = Vector2.ZERO  # Stop movement if attacking or player detected
			if sprite and sprite.animation != "attack1" and sprite.animation != "attack2":
				sprite.play("idle")  # Play idle animation
			if walk_sound and walk_sound.playing:
				walk_sound.stop()
	
	# Trigger attack if player is in attack range, cooldown is over, and not attacking
	if player_in_attack_range and current_time - last_attack_time >= attack_cooldown and not is_attacking:
		attack_type = "attack2" if randf() < 0.5 else "attack1"
		if attack_type == "attack1":
			attack1()
		else:
			attack2()
	
	global_position += velocity * delta

func _on_attack_area_body_entered(body: Node):
	if body.name == "Player" and not is_attacking:
		player_in_attack_range = true
		attack_type = "attack2" if randf() < 0.5 else "attack1"
		if attack_type == "attack1":
			attack1()
		else:
			attack2()

func _on_attack_area_body_exited(body: Node):
	if body.name == "Player":
		player_in_attack_range = false

func _on_detection_area_body_entered(body: Node):
	if body.name == "Player":
		player_in_detection_range = true

func _on_detection_area_body_exited(body: Node):
	if body.name == "Player":
		player_in_detection_range = false

func move_towards_player(delta: float):
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	
	# Flip sprite and adjust collision shape based on movement direction
	if velocity.x < 0:
		sprite.flip_h = false
		collision_shape.position = Vector2(9, 20)  # Position for moving left
		detection_area.position = Vector2(0, 0)
	elif velocity.x > 0:
		sprite.flip_h = true
		collision_shape.position = Vector2(-9, 20)  # Position for moving right
		detection_area.position = Vector2(-20, 0)
		
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
		
		var coin_count = randi_range(30, 50)
		for i in range(coin_count):
			var coin_instance = create_coin_item()
			coin_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			ground_node.add_child(coin_instance)
	
	var cave_entrance_spawner = get_tree().root.get_node("Ground/World/CaveEntrance")
	if cave_entrance_spawner and cave_entrance_spawner.has_method("on_unstoppable_died"):
		cave_entrance_spawner.on_unstoppable_died()
	
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

func attack1():
	is_attacking = true
	velocity = Vector2.ZERO
	
	if sprite is AnimatedSprite2D:
		sprite.play("attack1")  # Play attack1 animation
	
	# Play roar sound
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
				print("Undead attacked player with cone for " + str(attack_damage) + " damage!")
				break
	)
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		cone.queue_free()
		is_attacking = false
		last_attack_time = Time.get_ticks_msec() / 1000.0
		if sprite is AnimatedSprite2D:
			sprite.play("walk")  # Return to walk animation after attack
	)

func attack2():
	is_attacking = true
	velocity = Vector2.ZERO
	
	if sprite is AnimatedSprite2D:
		sprite.play("attack2")  # Play attack2 animation
	
	# Play roar sound
	if roar_sound and not roar_sound.playing:
		roar_sound.play()
	
	# Create tween for 5 consecutive attacks
	var tween = create_tween()
	for i in range(5):
		tween.tween_callback(func():
			if sprite is AnimatedSprite2D:
				sprite.play("attack2")  # Replay attack2 animation for each hit
			
			# Create warning circle at player's current position
			var circle = Polygon2D.new()
			circle.color = Color(1, 0, 0, 0.3)  # Warning color
			circle.visible = true
			add_child(circle)
			
			# Generate circle points (radius 10)
			var radius = 10.0
			var points = []
			var num_points = 32
			for j in range(num_points + 1):
				var angle = j * 2 * PI / num_points
				var point = Vector2(cos(angle), sin(angle)) * radius
				points.append(point)
			circle.polygon = points
			circle.global_position = player.global_position  # Position at player's location
			
			# Create tween for warning and damage
			var circle_tween = create_tween()
			circle_tween.tween_interval(0.8)  # Warning period
			circle_tween.tween_callback(func():
				circle.color = Color(1, 0, 0, 0.8)  # Damage color
				var space_state = get_world_2d().direct_space_state
				var query = PhysicsShapeQueryParameters2D.new()
				var circle_shape = CircleShape2D.new()
				circle_shape.radius = radius
				query.shape = circle_shape
				query.transform = Transform2D(0, circle.global_position)
				query.collision_mask = 1
				
				var results = space_state.intersect_shape(query)
				for result in results:
					if result.collider == player and player.has_method("take_damage"):
						player.take_damage(attack_damage)
						print("Undead attacked player with circle for " + str(attack_damage) + " damage!")
						break
			)
			circle_tween.tween_interval(0.3)  # Damage display period
			circle_tween.tween_callback(circle.queue_free)  # Remove circle
		)
		tween.tween_interval(1.1)  # Total interval per attack (0.8 warning + 0.3 damage)
	
	tween.tween_callback(func():
		is_attacking = false
		last_attack_time = Time.get_ticks_msec() / 1000.0
		if sprite is AnimatedSprite2D:
			sprite.play("walk")  # Return to walk animation after attack
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
