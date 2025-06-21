extends CharacterBody2D

@export var max_health: int = 100
var current_health: int
@export var normal_speed: float = 15.0     # Tốc độ bình thường
@export var flee_speed: float = 150.0      # Tốc độ khi chạy trốn
@export var roam_range: float = 300.0      # Phạm vi để bắt đầu roaming
@onready var player = get_tree().root.get_node("Ground/Player") if get_tree().root.has_node("Ground/Player") else null
@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var audio_player = $AudioStreamPlayer2D
var is_fleeing: bool = false
var flee_timer: float = 0.0
var is_immobilized: bool = false
var immobilize_timer: float = 0.0
var is_roaming: bool = false
var roam_direction: Vector2
var roam_timer: float = 0.0
var is_moving: bool = false
var move_duration: float
var stop_duration: float
var avoidance_rays: Array[RayCast2D] = []
var avoidance_angles: Array[float] = [0]  # Giảm xuống chỉ 1 raycast (0°)
var avoidance_distance: float = 50.0
var moo_timer: float = 0.0
var moo_interval: float
var update_interval: float = 0.1  # Tần suất cập nhật logic (0.1 giây)
var update_timer: float = 0.0
var roam_range_squared: float  # Khoảng cách bình phương
var need_raycast_update: bool = false

func _ready():
	current_health = max_health
	roam_range_squared = roam_range * roam_range
	if not player:
		print("Warning: Player node not found!")
	
	sprite.frame = 0
	
	move_duration = randf_range(1.0, 3.0)
	stop_duration = randf_range(10.0, 20.0)
	moo_interval = randf_range(5.0, 15.0)
	
	# Tạo raycast duy nhất
	for angle in avoidance_angles:
		var ray = RayCast2D.new()
		ray.enabled = true
		ray.target_position = Vector2(cos(angle), sin(angle)) * avoidance_distance
		ray.collision_mask = 1
		add_child(ray)
		avoidance_rays.append(ray)

func _physics_process(delta: float):
	if not player:
		return
	
	update_timer -= delta
	moo_timer -= delta
	
	if update_timer <= 0:
		update_timer = update_interval
		var distance_squared_to_player = global_position.distance_squared_to(player.global_position)
		
		if is_immobilized:
			velocity = Vector2.ZERO
			immobilize_timer -= delta * (update_interval / delta)
			if immobilize_timer <= 0:
				is_immobilized = false
				sprite.modulate = Color(1, 1, 1)
			return
		
		if is_fleeing:
			flee_from_player(delta)
			flee_timer -= delta * (update_interval / delta)
			if flee_timer <= 0:
				is_fleeing = false
				velocity = Vector2.ZERO
		elif distance_squared_to_player <= roam_range_squared:
			is_roaming = true
			roam(delta)
		else:
			is_roaming = false
			velocity = Vector2.ZERO
	
	if velocity != Vector2.ZERO:
		move_and_slide()
		update_sprite_direction()

func flee_from_player(delta: float):
	var target_direction = (global_position - player.global_position).normalized()
	
	if need_raycast_update:
		var angle_to_direction = atan2(target_direction.y, target_direction.x)
		var ray = avoidance_rays[0]
		ray.target_position = Vector2(cos(angle_to_direction), sin(angle_to_direction)) * avoidance_distance
		ray.force_raycast_update()
		need_raycast_update = false
	
	var best_direction = target_direction
	if avoidance_rays[0].is_colliding():
		best_direction = target_direction.rotated(PI/8)
	
	velocity = best_direction * flee_speed

func roam(delta: float):
	roam_timer -= delta * (update_interval / delta)
	if roam_timer <= 0:
		if is_moving:
			is_moving = false
			roam_timer = stop_duration
			velocity = Vector2.ZERO
		else:
			is_moving = true
			roam_timer = move_duration
			var random_angle = randf() * 2 * PI
			roam_direction = Vector2(cos(random_angle), sin(random_angle))
			need_raycast_update = true
	
	if not is_moving:
		velocity = Vector2.ZERO
		return
	
	var target_direction = roam_direction
	
	if need_raycast_update:
		var angle_to_direction = atan2(target_direction.y, target_direction.x)
		var ray = avoidance_rays[0]
		ray.target_position = Vector2(cos(angle_to_direction), sin(angle_to_direction)) * avoidance_distance
		ray.force_raycast_update()
		need_raycast_update = false
	
	var best_direction = target_direction
	if avoidance_rays[0].is_colliding():
		best_direction = target_direction.rotated(PI/8)
	
	velocity = best_direction * normal_speed

func update_sprite_direction():
	if velocity == Vector2.ZERO:
		return

	var angle = velocity.angle()
	var direction = rad_to_deg(angle)

	if direction >= -45 and direction < 45:
		sprite.frame = 2
	elif direction >= 45 and direction < 135:
		sprite.frame = 0
	elif direction >= 135 or direction < -135:
		sprite.frame = 3
	else:
		sprite.frame = 1

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		die()
	else:
		is_fleeing = true
		flee_timer = 3.0
		is_roaming = false
		need_raycast_update = true
		play_moo_sound()

func die():
	var ground_node = get_tree().root.get_node("Ground")
	if ground_node:
		var leather_instance = create_leather_item()
		leather_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
		ground_node.add_child(leather_instance)
		
		var meat_instance = create_meat_item()
		meat_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
		ground_node.add_child(meat_instance)
		
		var coin_chance = randf()
		if coin_chance <= 0.3:
			var coin_instance = create_coin_item()
			coin_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
			ground_node.add_child(coin_instance)
	
	var spawner = find_spawner_for_entity()
	if spawner:
		spawner.remove_entity(self)
	
	queue_free()

func create_leather_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var leather = item_scene.instantiate()
	leather.item_name = "Leather"
	return leather

func create_meat_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var meat = item_scene.instantiate()
	meat.item_name = "RawMeat"
	return meat

func create_coin_item() -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var coin = item_scene.instantiate()
	coin.item_name = "Coin"
	return coin

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
	if node.get_script() and node.get_script().resource_path == "res://World/Cow/cow_spawner.gd":
		spawners.append(node)
	for child in node.get_children():
		find_spawners_recursive(child, spawners)

func play_moo_sound():
	if audio_player and not audio_player.playing:
		audio_player.play()
