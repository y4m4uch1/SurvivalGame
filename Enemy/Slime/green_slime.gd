extends CharacterBody2D

@export var max_health: int = 100
var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()
@onready var day_night_cycle = get_tree().root.get_node("/root/Ground/World/DayNightWeather")

var current_health: int
var attack_damage: int = 20
var attack_cooldown: float = 3.0
var last_attack_time: float = 0.0
@export var detection_range: float = 200.0
@export var move_speed: float = 19.0
@onready var player = get_tree().root.get_node("Ground/Player")
@onready var raycast = $RayCast2D
@onready var sprite = $Sprite2D
@onready var area_2d = $Area2D  # Thêm tham chiếu đến Area2D
@onready var detection_area = $DetectionArea  # Thêm tham chiếu đến DetectionArea

var attack_circle: Polygon2D
var is_attacking: bool = false
var is_immobilized: bool = false
var immobilize_timer: float = 0.0

var move_animation_timer: float = 0.0
var move_animation_speed: float = 0.2

var structure_in_range: StaticBody2D = null
var targets_in_range: Array = []  # Lưu danh sách các đối tượng trong phạm vi Area2D

var avoidance_rays: Array[RayCast2D] = []
var avoidance_angles: Array[float] = [-PI/4, 0, PI/4]
var avoidance_distance: float = 50.0
var saved_health: int = -1
var is_knocked_back: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.3
var knockback_timer: float = 0.0
var knockback_base_strength: float = 10.0
var is_player_in_detection: bool = false

func _ready():
	add_to_group("enemy")
	if saved_health >= 0:
		current_health = saved_health
	else:
		current_health = max_health
	
	collision_layer = 1  # Ensure CharacterBody2D is on layer 1
	collision_mask = 1   # Detect collisions with layer 1
	
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
	
	attack_circle = Polygon2D.new()
	attack_circle.color = Color(1, 0, 0, 0.3)
	attack_circle.visible = false
	add_child(attack_circle)
	draw_circle_points(attack_circle, 0.0)
	
	sprite.frame = 0
	
	# Ensure Area2D has proper collision shape
	var collision_shape = area_2d.get_node_or_null("CollisionShape2D")
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 25.0
		collision_shape.shape = circle_shape
		area_2d.add_child(collision_shape)
	area_2d.collision_layer = 1
	area_2d.collision_mask = 1
	
	# Kết nối tín hiệu của DetectionArea
	var detection_collision_shape = detection_area.get_node_or_null("CollisionShape2D")
	if not detection_collision_shape:
		detection_collision_shape = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 200
		detection_collision_shape.shape = circle_shape
		detection_area.add_child(detection_collision_shape)
	detection_area.collision_layer = 2
	detection_area.collision_mask = 1
	
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Tắt physics process ban đầu
	set_physics_process(false)
	
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body == player:
		set_physics_process(true)  # Bật physics process khi player vào vùng
		is_player_in_detection = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		set_physics_process(false)  # Tắt physics process khi player rời vùng
		is_player_in_detection = false
		
func _physics_process(delta: float):
	if not player or not day_night_cycle or is_knocked_back or is_immobilized:
		if is_knocked_back:
			velocity = knockback_velocity
			knockback_timer -= delta
			if knockback_timer <= 0:
				is_knocked_back = false
				velocity = Vector2.ZERO
		elif is_immobilized:
			velocity = Vector2.ZERO
			immobilize_timer -= delta
			if immobilize_timer <= 0:
				is_immobilized = false
				sprite.modulate = Color(1, 1, 1)
		move_and_slide()
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var distance_to_player = global_position.distance_to(player.global_position)
	if day_night_cycle.is_raining or is_player_in_detection:
		if not is_attacking and not structure_in_range:
			move_towards_player(delta)
			update_move_animation(delta)
		else:
			velocity = Vector2.ZERO
	else:
		if not is_attacking:
			sprite.frame = 0
			move_animation_timer = 0.0
	
	if targets_in_range.size() > 0 and current_time - last_attack_time >= attack_cooldown:
		attack()
		last_attack_time = current_time
	
	move_and_slide()

func _on_body_entered(body: Node2D) -> void:
	if body == player or (body is StaticBody2D and body.has_meta("structure_name") and body.get_meta("structure_name") != "Trader"):
		if not targets_in_range.has(body):
			targets_in_range.append(body)
			if body is StaticBody2D:
				structure_in_range = body
				var structure_name = body.get_meta("structure_name")
				if structure_name in item_data["Structure"] and not body.has_meta("health"):
					if item_data["Structure"][structure_name].has("health"):
						body.set_meta("health", item_data["Structure"][structure_name]["health"])

func _on_body_exited(body: Node2D) -> void:
	if targets_in_range.has(body):
		targets_in_range.erase(body)
		if body is StaticBody2D:
			structure_in_range = null

func update_move_animation(delta: float):
	move_animation_timer += delta
	if move_animation_timer >= move_animation_speed:
		sprite.frame = 1 if sprite.frame == 0 else 0
		move_animation_timer = 0.0

func move_towards_player(delta: float):
	var target_direction = (player.global_position - global_position).normalized()
	var angle_to_player = atan2(target_direction.y, target_direction.x)
	var is_blocked = false
	var best_direction = target_direction

	avoidance_rays[1].target_position = target_direction * avoidance_distance
	avoidance_rays[1].force_raycast_update()
	if avoidance_rays[1].is_colliding():
		is_blocked = true
		for i in [0, 2]:
			var ray = avoidance_rays[i]
			var ray_angle = angle_to_player + avoidance_angles[i]
			ray.target_position = Vector2(cos(ray_angle), sin(ray_angle)) * avoidance_distance
			ray.force_raycast_update()
			if not ray.is_colliding():
				best_direction = Vector2(cos(ray_angle), sin(ray_angle))
				break

	if is_blocked and best_direction == target_direction:
		best_direction = target_direction.rotated(PI/8)
	
	velocity = best_direction * move_speed

func take_damage(amount: int):
	current_health -= amount
	if not is_knocked_back and player:
		is_knocked_back = true
		knockback_timer = knockback_duration
		var direction = (global_position - player.global_position).normalized()
		var knockback_strength = knockback_base_strength * (amount / 10.0)
		knockback_velocity = direction * knockback_strength
		
		# Tạo hiệu ứng nhấp nháy
		create_blink_effect()
	if current_health <= 0:
		die()

func create_blink_effect():
	var tween = create_tween()
	tween.set_loops(3) # Nhấp nháy 3 lần
	tween.tween_property(sprite, "visible", false, 0.1) # Tắt trong 0.1s
	tween.tween_property(sprite, "visible", true, 0.1)  # Bật trong 0.1s

func die():
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
	
	var spawner = find_spawner_for_entity()
	if spawner:
		spawner.remove_entity(self)
	
	queue_free()

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
	sprite.frame = 2
	attack_circle.visible = true
	var tween = create_tween()
	tween.tween_method(update_circle_radius, 0.0, 25.0, 0.8)
	tween.tween_callback(func():
		var attacked_something = false
		var targets_to_remove = []
		print("Slime attacking, targets in range: ", targets_in_range.size())
		for target in targets_in_range:
			if not is_instance_valid(target):
				targets_to_remove.append(target)
				continue
			print("Processing target: ", target.name, " type: ", target.get_class())
			if target == player and player.has_method("take_damage"):
				player.take_damage(attack_damage)
				print("Slime attacked player for " + str(attack_damage) + " damage!")
				attacked_something = true
			elif target is StaticBody2D and target.has_meta("structure_name"):
				var structure_name = target.get_meta("structure_name")
				print("Target structure_name: ", structure_name)
				if structure_name in item_data["Structure"]:
					if item_data["Structure"][structure_name].has("health"):
						if structure_name == "WoodenSpikes" and target.has_method("take_damage"):
							target.take_damage(attack_damage, self)  # Truyền self làm attacker
							if not is_instance_valid(target):  # Nếu target đã bị phá hủy
								targets_to_remove.append(target)
								structure_in_range = null
							print("Slime attacked WoodenSpikes for " + str(attack_damage) + " damage!")
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
									targets_to_remove.append(target)
									structure_in_range = null
									attacked_something = true
					else:
						# Structure không có health, phá hủy ngay lập tức
						destroy_structure(target)
						targets_to_remove.append(target)
						structure_in_range = null
						attacked_something = true
						print("Slime instantly destroyed structure ", structure_name, " (no health attribute)")
		
		# Xóa các target không còn hợp lệ hoặc đã bị phá hủy
		for target in targets_to_remove:
			targets_in_range.erase(target)
		
		attack_circle.visible = false
		is_attacking = false
		if not attacked_something and velocity == Vector2.ZERO:
			sprite.frame = 0
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

func immobilize(duration: float):
	is_immobilized = true
	immobilize_timer = duration
	sprite.modulate = Color(0.5, 0.5, 0.5)

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

func set_saved_health(health: int):
	saved_health = health
	current_health = health
