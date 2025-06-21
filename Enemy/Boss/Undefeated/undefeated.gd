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
	"res://World/Enemy/Boss/Undefeated/UndefeatedMusic1.wav",
	"res://World/Enemy/Boss/Undefeated/UndefeatedMusic2.wav",
	"res://World/Enemy/Boss/Undefeated/UndefeatedMusic3.wav"
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
		if sprite and sprite.animation != "attack1" and sprite.animation != "attack2" and sprite.animation != "attack3":
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
			# Linearly interpolate raycast distance from 10 to 50 based on delta_y
			var max_delta_y = 60.0  # Y difference at which raycast distance reaches 50
			var raycast_distance = lerp(10.0, 45.0, clamp(delta_y / max_delta_y, 0.0, 1.0))
			
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
			if sprite and sprite.animation != "attack1" and sprite.animation != "attack2" and sprite.animation != "attack3":
				sprite.play("idle")  # Play idle animation
			if walk_sound and walk_sound.playing:
				walk_sound.stop()
	
	# Trigger attack if player is in attack range, cooldown is over, and not attacking
	if player_in_attack_range and current_time - last_attack_time >= attack_cooldown and not is_attacking:
		var random_value = randf()
		if random_value < 0.333:
			attack_type = "attack1"
			attack1()
		elif random_value < 0.666:
			attack_type = "attack2"
			attack2()
		else:
			attack_type = "attack3"
			attack3()
	
	global_position += velocity * delta

func _on_attack_area_body_entered(body: Node):
	if body.name == "Player" and not is_attacking:
		player_in_attack_range = true
		var random_value = randf()
		if random_value < 0.333:
			attack_type = "attack1"
			attack1()
		elif random_value < 0.666:
			attack_type = "attack2"
			attack2()
		else:
			attack_type = "attack3"
			attack3()

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
	
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

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
	
	if sprite:
		sprite.play("attack1")
	
	if roar_sound and not roar_sound.playing:
		roar_sound.play()
	
	var circle_radius = 40.0
	var min_distance = 0.0
	var max_distance = 200.0
	var circles = []
	var num_points = 32
	for i in range(6):
		var circle = Polygon2D.new()
		circle.color = Color(1, 0, 0, 0.3)
		var angle = randf() * 2 * PI
		var distance = randf_range(min_distance, max_distance)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		circle.position = player.global_position + offset - global_position
		var circle_points = []
		for j in range(num_points + 1):
			var circle_angle = j * 2 * PI / num_points
			var point = Vector2(cos(circle_angle), sin(circle_angle)) * circle_radius
			circle_points.append(point)
		circle.polygon = circle_points
		add_child(circle)
		circles.append(circle)
	
	var tween = create_tween()
	tween.tween_interval(1.3)
	tween.tween_callback(func():
		for circle in circles:
			circle.color = Color(1, 0, 0, 1.3)
		
		var space_state = get_world_2d().direct_space_state
		for circle in circles:
			var circle_query = PhysicsShapeQueryParameters2D.new()
			var circle_shape = CircleShape2D.new()
			circle_shape.radius = circle_radius
			circle_query.shape = circle_shape
			circle_query.transform = Transform2D(0, global_position + circle.position)
			circle_query.collision_mask = 1
			
			var circle_results = space_state.intersect_shape(circle_query)
			for result in circle_results:
				if result.collider == player and player.has_method("take_damage"):
					player.take_damage(attack_damage)
					print("Undefeated attacked player with circle for " + str(attack_damage) + " damage!")
					break
	)
	tween.tween_interval(0.3)
	tween.tween_callback(func():
		for circle in circles:
			circle.queue_free()
		is_attacking = false
		last_attack_time = Time.get_ticks_msec() / 1000.0
		if sprite:
			sprite.play("walk")
	)

func attack2():
	is_attacking = true
	velocity = Vector2.ZERO
	
	if sprite:
		sprite.play("attack2")
	
	if roar_sound and not roar_sound.playing:
		roar_sound.play()
	
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func():
		var projectile_scene = preload("res://World/Enemy/Boss/Undefeated/Projectile.tscn")
		var spread_angle = deg_to_rad(10)
		var total_spread = spread_angle * 4
		var base_direction = (player.global_position - global_position).normalized()
		var base_angle = atan2(base_direction.y, base_direction.x)
		
		for i in range(5):
			var angle_offset = base_angle - total_spread / 2 + (i * spread_angle)
			var direction = Vector2(cos(angle_offset), sin(angle_offset))
			var projectile = projectile_scene.instantiate()
			projectile.global_position = global_position
			projectile.direction = direction
			projectile.velocity = direction * projectile.speed
			get_tree().root.get_node("Ground").add_child(projectile)
		
		is_attacking = false
		last_attack_time = Time.get_ticks_msec() / 1000.0
		if sprite:
			sprite.play("walk")
	)

func attack3():
	is_attacking = true
	velocity = Vector2.ZERO
	
	if sprite:
		sprite.play("attack3")
	
	if roar_sound and not roar_sound.playing:
		roar_sound.play()
	
	var cone = Polygon2D.new()
	cone.color = Color(1, 0, 0, 0.3)
	cone.visible = true
	add_child(cone)
	
	var cone_angle = deg_to_rad(180)
	var cone_radius = attack_range + 5
	var direction = (player.global_position - global_position).normalized()
	var center_angle = atan2(direction.y, direction.x)
	
	var points = []
	var num_points = 32
	points.append(Vector2.ZERO)
	for i in range(num_points + 1):
		var angle = center_angle - cone_angle / 2 + (cone_angle * i / num_points)
		var point = Vector2(cos(angle), sin(angle)) * cone_radius
		points.append(point)
	cone.polygon = points
	
	var tween = create_tween()
	tween.tween_interval(1)
	tween.tween_callback(func():
		cone.color = Color(1, 0, 0, 1)
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
	tween.tween_interval(0.5)
	tween.tween_callback(func():
		cone.queue_free()
		is_attacking = false
		last_attack_time = Time.get_ticks_msec() / 1000.0
		if sprite:
			sprite.play("walk")
	)

func update_circle_radius(radius: float):
	draw_circle_points(attack_circle, 2)

func draw_circle_points(polygon: Polygon2D, radius: float):
	var points = []
	var num_points = 32
	for i in range(num_points + 1):
		var angle = i * 2 * PI / num_points
		var point = Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	polygon.polygon = points
