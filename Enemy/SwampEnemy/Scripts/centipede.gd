extends CharacterBody2D

@export var max_health: int = 100
var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()
@onready var day_night_cycle = get_tree().root.get_node("/root/Ground/World/DayNightWeather")

var current_health: int
var attack_damage: int = 20
var attack_cooldown: float = 2.0
var last_attack_time: float = 0.0
@export var detection_range: float = 200.0
@export var move_speed: float = 19.0
@onready var player = get_tree().root.get_node("Ground/Player")
@onready var raycast = $RayCast2D
@onready var sprite = $AnimatedSprite2D
@onready var area_2d = $Area2D
@onready var collision_shape = $CollisionShape2D
@onready var collision_shape2 = $CollisionShape2D2
@onready var detection_area = $DetectionArea

var attack_raycast: RayCast2D
var attack_range: float = 60.0
var attack_line: Line2D
var circle_attack_visual: Polygon2D
var is_attacking: bool = false
var is_immobilized: bool = false
var immobilize_timer: float = 0.0
var is_dead: bool = false
var move_animation_timer: float = 0.0
var move_animation_speed: float = 0.2
var is_player_in_detection: bool = false

var structure_in_range: StaticBody2D = null
var targets_in_range: Array = []

var avoidance_rays: Array[RayCast2D] = []
var avoidance_angles: Array[float] = [-PI/4, 0, PI/4]
var avoidance_distance: float = 50.0
var saved_health: int = -1

# Knockback variables
var is_knocked_back: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.3
var knockback_timer: float = 0.0
var knockback_base_strength: float = 10.0

# Attack 1 (circle) variables
var circle_attack_radius: float = 30.0

func _ready():
	add_to_group("enemy")
	if saved_health >= 0:
		current_health = saved_health
	else:
		current_health = max_health
	
	collision_layer = 1
	collision_mask = 1
	
	if not player:
		print("Warning: Player node not found!")
	
	if not raycast:
		raycast = RayCast2D.new()
		add_child(raycast)
	raycast.enabled = true
	raycast.target_position = Vector2(25.0, 0)
	raycast.collision_mask = 1
	
	for angle in avoidance_angles:
		var ray = RayCast2D.new()
		ray.enabled = true
		ray.target_position = Vector2(cos(angle), sin(angle)) * avoidance_distance
		ray.collision_mask = 1
		add_child(ray)
		avoidance_rays.append(ray)
	
	attack_raycast = RayCast2D.new()
	attack_raycast.enabled = true
	attack_raycast.target_position = Vector2(attack_range, 0)
	attack_raycast.collision_mask = 1
	add_child(attack_raycast)
	
	attack_line = Line2D.new()
	attack_line.default_color = Color(1, 0, 0, 0.3)
	attack_line.width = 25.0
	attack_line.visible = false
	add_child(attack_line)
	
	circle_attack_visual = Polygon2D.new()
	circle_attack_visual.color = Color(1, 0, 0, 0.3)
	circle_attack_visual.visible = false
	add_child(circle_attack_visual)
	draw_circle_points(circle_attack_visual, circle_attack_radius)
	
	sprite.play("idle")
	
	var collision_shape_attack = area_2d.get_node_or_null("CollisionShape2D")
	if not collision_shape_attack:
		collision_shape_attack = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 44.5533
		collision_shape_attack.shape = circle_shape
		area_2d.add_child(collision_shape_attack)
	area_2d.collision_layer = 1
	area_2d.collision_mask = 1
	
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)
	
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta: float):
	if not player or not day_night_cycle or is_dead:
		return
		
	if is_knocked_back:
		velocity = knockback_velocity
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_knocked_back = false
			velocity = Vector2.ZERO
		if velocity != Vector2.ZERO:
			move_and_slide()
		return
	
	if is_immobilized:
		velocity = Vector2.ZERO
		immobilize_timer -= delta
		if immobilize_timer <= 0:
			is_immobilized = false
			sprite.modulate = Color(1, 1, 1)
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if day_night_cycle.is_raining:
		if not is_attacking:
			if not structure_in_range and is_player_in_detection:
				move_towards_player(delta)
				update_move_animation(delta)
			else:
				velocity = Vector2.ZERO
				sprite.play("idle")
	else:
		if is_player_in_detection and not is_attacking:
			if not structure_in_range:
				move_towards_player(delta)
				update_move_animation(delta)
			else:
				velocity = Vector2.ZERO
				sprite.play("idle")
		else:
			if not is_attacking:
				sprite.play("idle")
				move_animation_timer = 0.0
	
	if (targets_in_range.size() > 0) and current_time - last_attack_time >= attack_cooldown and not is_attacking:
		attack()
		last_attack_time = current_time
	
	if velocity != Vector2.ZERO:
		move_and_slide()

func _on_body_entered(body: Node2D) -> void:
	if body == player or (body is StaticBody2D and body.has_meta("structure_name") and body.get_meta("structure_name") != "Trader"):
		if not targets_in_range.has(body):
			targets_in_range.append(body)
			if body is StaticBody2D and body.has_meta("structure_name"):
				var structure_name = body.get_meta("structure_name")
				if structure_name in item_data["Structure"]:
					if not body.has_meta("health") and item_data["Structure"][structure_name].has("health"):
						body.set_meta("health", item_data["Structure"][structure_name]["health"])
					structure_in_range = body

func _on_body_exited(body: Node2D) -> void:
	if targets_in_range.has(body):
		targets_in_range.erase(body)
		if body is StaticBody2D and body == structure_in_range:
			structure_in_range = null

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body == player:
		is_player_in_detection = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		is_player_in_detection = false

func update_move_animation(delta: float):
	sprite.play("walk")
	move_animation_timer += delta
	if move_animation_timer >= move_animation_speed:
		move_animation_timer = 0.0
	
	if velocity.x < -10:
		sprite.flip_h = false
		collision_shape.position = Vector2(13, 26)
		collision_shape2.position = Vector2(-1, 18)
		area_2d.position = Vector2(0, 0)
	elif velocity.x > 10:
		sprite.flip_h = true
		collision_shape.position = Vector2(-14, 26)
		collision_shape2.position = Vector2(2, 18)
		area_2d.position = Vector2(-20, 0)

func move_towards_player(delta: float):
	var target_direction = (player.global_position - global_position).normalized()
	
	var angle_to_player = atan2(target_direction.y, target_direction.x)
	for i in range(avoidance_rays.size()):
		var ray = avoidance_rays[i]
		var ray_angle = angle_to_player + avoidance_angles[i]
		ray.target_position = Vector2(cos(ray_angle), sin(ray_angle)) * avoidance_distance
		ray.force_raycast_update()
	
	var best_direction = target_direction
	var min_angle_diff = PI
	var is_blocked = false
	
	if avoidance_rays[1].is_colliding():
		is_blocked = true
		for i in range(avoidance_rays.size()):
			var ray = avoidance_rays[i]
			if not ray.is_colliding():
				var ray_angle = angle_to_player + avoidance_angles[i]
				var test_direction = Vector2(cos(ray_angle), sin(ray_angle))
				var angle_diff = abs(target_direction.angle_to(test_direction))
				if angle_diff < min_angle_diff:
					min_angle_diff = angle_diff
					best_direction = test_direction
	
	if is_blocked and best_direction == target_direction:
		best_direction = target_direction.rotated(PI/8)
	
	velocity = best_direction * move_speed

func take_damage(amount: int):
	current_health -= amount
	
	if not is_dead and player:
		is_knocked_back = true
		knockback_timer = knockback_duration
		var direction = (global_position - player.global_position).normalized()
		var knockback_strength = knockback_base_strength * (amount / 10.0)
		knockback_velocity = direction * knockback_strength
	
	if current_health <= 0:
		die()

func die():
	print("Centipede dying")
	is_dead = true
	sprite.play("death")
	sprite.sprite_frames.set_animation_loop("death", false)
	var frame_count = sprite.sprite_frames.get_frame_count("death")
	var frame_duration = 1.0 / sprite.sprite_frames.get_animation_speed("death")
	var total_duration = frame_count * frame_duration
	print("Death animation duration:", total_duration)
	var tween = create_tween()
	tween.tween_callback(func():
		print("Freeing centipede")
		queue_free()
	).set_delay(total_duration)
	
	var ground_node = get_tree().root.get_node("Ground")
	if ground_node:
		var gel_chance = randf()
		if gel_chance <= 0.5:
			var gel_instance = create_slime_gel_item()
			gel_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			ground_node.add_child(gel_instance)
		
		var coin_chance = randf()
		if coin_chance <= 0.5:
			var coin_instance = create_coin_item()
			coin_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			ground_node.add_child(coin_instance)

func create_slime_gel_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var gel = item_scene.instantiate()
	gel.item_name = "SlimeGel"
	return gel

func create_coin_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var coin = item_scene.instantiate()
	coin.item_name = "Coin"
	return coin

func attack():
	is_attacking = true
	velocity = Vector2.ZERO
	var attack_animations = ["attack1", "attack2"]
	var selected_attack = attack_animations[randi() % attack_animations.size()]
	sprite.play(selected_attack)
	
	var frame_count = sprite.sprite_frames.get_frame_count(selected_attack)
	var frame_duration = 1.0 / sprite.sprite_frames.get_animation_speed(selected_attack)
	var attack_duration = frame_count * frame_duration
	var warning_duration = attack_duration * 0.67
	var damage_duration = attack_duration * 0.33
	
	var direction = (player.global_position - global_position).normalized()
	var attacked_something = false
	
	if selected_attack == "attack2":
		var angle = atan2(direction.y, direction.x)
		attack_raycast.target_position = direction * attack_range
		attack_raycast.force_raycast_update()
		
		attack_line.points = [Vector2.ZERO, direction * attack_range]
		attack_line.default_color = Color(1, 0, 0, 0.3)
		attack_line.visible = true
		
		var tween = create_tween()
		tween.tween_interval(warning_duration)
		tween.tween_callback(func():
			attack_line.default_color = Color(1, 0, 0, 0.8)
			if attack_raycast.is_colliding():
				var target = attack_raycast.get_collider()
				if is_instance_valid(target):
					if target == player and target.has_method("take_damage"):
						target.take_damage(attack_damage)
						attacked_something = true
					elif target is StaticBody2D and target.has_meta("structure_name"):
						var structure_name = target.get_meta("structure_name")
						if structure_name in item_data["Structure"]:
							if item_data["Structure"][structure_name].has("health"):
								if structure_name == "WoodenSpikes" and target.has_method("take_damage"):
									target.take_damage(attack_damage, self)
									if not is_instance_valid(target):
										targets_in_range.erase(target)
										structure_in_range = null
									attacked_something = true
								else:
									var tile_pos = Vector2(
										(target.global_position.x / 16.0),
										(target.global_position.y / 16.0)
									)
									var player_node = get_tree().root.get_node("Ground/Player")
									if player_node and player_node.has_method("damage_structure"):
										var was_destroyed = player_node.damage_structure(structure_name, tile_pos, attack_damage)
										if was_destroyed:
											destroy_structure(target)
											targets_in_range.erase(target)
											structure_in_range = null
											attacked_something = true
							else:
								destroy_structure(target)
								targets_in_range.erase(target)
								structure_in_range = null
								attacked_something = true
		)
		tween.tween_interval(damage_duration)
		tween.tween_callback(func():
			attack_line.visible = false
			is_attacking = false
			if not attacked_something and velocity == Vector2.ZERO and targets_in_range.size() == 0:
				sprite.play("idle")
		)
	
	elif selected_attack == "attack1":
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsShapeQueryParameters2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = circle_attack_radius
		query.shape = circle_shape
		var circle_center = global_position + direction * (attack_range / 2.0)
		query.transform = Transform2D(0, circle_center)
		query.collide_with_bodies = true
		query.collision_mask = 1
		
		circle_attack_visual.position = direction * (attack_range / 2.0)
		circle_attack_visual.color = Color(1, 0, 0, 0.3)
		circle_attack_visual.visible = true
		
		var tween = create_tween()
		tween.tween_interval(warning_duration)
		tween.tween_callback(func():
			circle_attack_visual.color = Color(1, 0, 0, 0.8)
			var results = space_state.intersect_shape(query)
			for result in results:
				var target = result.collider
				if is_instance_valid(target):
					if target == player and target.has_method("take_damage"):
						target.take_damage(attack_damage)
						attacked_something = true
					elif target is StaticBody2D and target.has_meta("structure_name"):
						var structure_name = target.get_meta("structure_name")
						if structure_name in item_data["Structure"]:
							if item_data["Structure"][structure_name].has("health"):
								if structure_name == "WoodenSpikes" and target.has_method("take_damage"):
									target.take_damage(attack_damage, self)
									if not is_instance_valid(target):
										targets_in_range.erase(target)
										structure_in_range = null
									attacked_something = true
								else:
									var tile_pos = Vector2(
										(target.global_position.x / 16.0),
										(target.global_position.y / 16.0)
									)
									var player_node = get_tree().root.get_node("Ground/Player")
									if player_node and player_node.has_method("damage_structure"):
										var was_destroyed = player_node.damage_structure(structure_name, tile_pos, attack_damage)
										if was_destroyed:
											destroy_structure(target)
											targets_in_range.erase(target)
											structure_in_range = null
											attacked_something = true
							else:
								destroy_structure(target)
								targets_in_range.erase(target)
								structure_in_range = null
								attacked_something = true
		)
		tween.tween_interval(damage_duration)
		tween.tween_callback(func():
			circle_attack_visual.visible = false
			is_attacking = false
			if not attacked_something and velocity == Vector2.ZERO and targets_in_range.size() == 0:
				sprite.play("idle")
		)

func draw_circle_points(polygon: Polygon2D, radius: float):
	var points = []
	var num_points = 32
	for i in range(num_points + 1):
		var angle = i * 2 * PI / num_points
		var point = Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	polygon.polygon = points

func immobilize(duration: float):
	is_immobilized = true
	immobilize_timer = duration
	sprite.modulate = Color(0.5, 0.5, 0.5)

func destroy_structure(structure_node: StaticBody2D):
	var structure_name = structure_node.get_meta("structure_name")
	var structure_world_pos = structure_node.global_position

	var player_node = get_tree().root.get_node("Ground/Player")
	if player_node and player_node.placed_structures:
		var target_structure_data = null
		for structure in player_node.placed_structures:
			var stored_pos = Vector2(
				structure["tile_position"]["x"] * 16 + 8,
				structure["tile_position"]["y"] * 16 + 8
			)
			if (structure["structure_name"] == structure_name and
				structure_world_pos.distance_to(stored_pos) < 16):
				target_structure_data = structure
				break

		if target_structure_data:
			if structure_name in ["WoodenChest", "IronChest"] and structure_node.has_meta("chest_inventory"):
				var chest_inventory = structure_node.get_meta("chest_inventory")
				var item_scene = preload("res://GUI/Inventory/Item.tscn")
				var ground_node = get_tree().root.get_node("Ground")
				for item in chest_inventory:
					if item.is_empty():
						continue
					var dropped_item = item_scene.instantiate()
					dropped_item.item_name = item["name"]
					dropped_item.position = structure_world_pos + Vector2(randi_range(-10, 10), randi_range(-10, 10))
					if item.has("current_durability") and item["current_durability"] >= 0:
						dropped_item.set_meta("current_durability", item["current_durability"])
					ground_node.add_child(dropped_item)

			player_node.placed_structures.erase(target_structure_data)

	if structure_node and is_instance_valid(structure_node):
		structure_node.queue_free()
