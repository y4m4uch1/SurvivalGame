extends Node

@onready var player = get_node("/root/Ground/Player")
@onready var world = get_node("/root/Ground/World")
@onready var day_night_cycle = get_node("/root/Ground/World/DayNightWeather")
@onready var scan_timer = Timer.new()

const SCAN_INTERVAL: float = 3.0
const CULLING_DISTANCE_ENABLE: float = 500.0
const CULLING_DISTANCE_DISABLE: float = 550.0
const SCAN_RADIUS: float = 600.0
var is_player_moving: bool = false
var managed_containers: Array[String] = []
var no_culling_containers: Array[String] = []
var entity_states: Dictionary = {}

func _ready():
	if not player:
		push_error("Player node not found at /root/Ground/Player")
		return
	if not world:
		push_error("World node not found at /root/Ground/World")
		return
	
	# Tự động thu thập container
	for child in world.get_children():
		if child.name.ends_with("Container") or child.name in no_culling_containers:
			managed_containers.append(child.name)
	
	scan_timer.wait_time = SCAN_INTERVAL
	scan_timer.one_shot = false
	scan_timer.connect("timeout", Callable(self, "_on_scan_timeout"))
	add_child(scan_timer)
	# Chỉ khởi động timer nếu world đang hiển thị
	if world and world.visible:
		scan_timer.start()
		initialize_entity_states()

func initialize_entity_states():
	entity_states.clear()
	for container_name in managed_containers:
		if container_name in no_culling_containers:
			continue
		var container = world.get_node_or_null(container_name)
		if container:
			for entity in container.get_children():
				if entity is Node2D:
					entity_states[entity] = entity.visible
					entity.connect("tree_exited", Callable(self, "_on_entity_removed").bind(entity))

func _physics_process(delta):
	if not player or not world:
		return
	
	# Kiểm tra trạng thái của world
	if not world.visible:
		# Nếu world không hiển thị, dừng timer và bỏ qua culling
		if scan_timer.time_left > 0 or not scan_timer.is_stopped():
			scan_timer.stop()
		return
		
	if player and world.visible:
		var velocity = player.velocity if player.has_method("get_velocity") else Vector2.ZERO
		is_player_moving = velocity.length_squared() > 0.1
		if is_player_moving and scan_timer.time_left == 0:
			scan_timer.start()
		elif not is_player_moving and scan_timer.time_left > 0:
			scan_timer.stop()
	# Update no_culling_containers based on rain status
	if day_night_cycle:
		if day_night_cycle.is_raining and not no_culling_containers.has("SlimeContainer"):
			if managed_containers.has("SlimeContainer"):
				no_culling_containers.append("SlimeContainer")
		elif not day_night_cycle.is_raining and no_culling_containers.has("SlimeContainer"):
			no_culling_containers.erase("SlimeContainer")

func _on_scan_timeout():
	if not player or not world or not is_player_moving or not world.visible:
		scan_timer.stop()
		return
	
	var player_pos = player.global_position
	for container_name in managed_containers:
		if container_name in no_culling_containers:
			continue
		var container = world.get_node_or_null(container_name)
		if container:
			for entity in container.get_children():
				if entity is Node2D:
					var distance = player_pos.distance_to(entity.global_position)
					var current_state = entity_states.get(entity, true)
					
					if distance <= SCAN_RADIUS:
						if distance <= CULLING_DISTANCE_ENABLE and not current_state:
							_enable_entity(entity)
							entity_states[entity] = true
						elif distance > CULLING_DISTANCE_DISABLE and current_state:
							_disable_entity(entity)
							entity_states[entity] = false
					elif distance > SCAN_RADIUS and current_state:
						_disable_entity(entity)
						entity_states[entity] = false

func _enable_entity(entity: Node):
	if entity.has_method("set_visible") and not entity.visible:
		entity.visible = true
	if entity.has_method("set_process_mode") and entity.process_mode != Node.PROCESS_MODE_INHERIT:
		entity.process_mode = Node.PROCESS_MODE_INHERIT
	if entity is CollisionObject2D:
		if entity.collision_layer == 0 and entity.has_meta("original_collision_layer"):
			entity.collision_layer = entity.get_meta("original_collision_layer", 1)
		if entity.collision_mask == 0 and entity.has_meta("original_collision_mask"):
			entity.collision_mask = entity.get_meta("original_collision_mask", 1)
	_process_entity_children(entity, true)

func _disable_entity(entity: Node):
	if entity is CollisionObject2D:
		if not entity.has_meta("original_collision_layer"):
			entity.set_meta("original_collision_layer", entity.collision_layer)
		if not entity.has_meta("original_collision_mask"):
			entity.set_meta("original_collision_mask", entity.collision_mask)
	if entity.has_method("set_visible") and entity.visible:
		entity.visible = false
	if entity.has_method("set_process_mode") and entity.process_mode != Node.PROCESS_MODE_DISABLED:
		entity.process_mode = Node.PROCESS_MODE_DISABLED
	if entity is CollisionObject2D:
		entity.collision_layer = 0
		entity.collision_mask = 0
	_process_entity_children(entity, false)

func _process_entity_children(entity: Node, enable: bool):
	for child in entity.get_children():
		if child is Node2D:
			if enable:
				_enable_entity(child)
			else:
				_disable_entity(child)

func _on_entity_removed(entity: Node):
	entity_states.erase(entity)
