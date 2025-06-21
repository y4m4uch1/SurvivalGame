extends Node2D

@onready var map_camera: Camera2D = $MapCamera
var is_active: bool = false

# Giới hạn zoom
var min_zoom: float = 0.5
var max_zoom: float = 2.0
var zoom_speed: float = 0.1

# Biến để xử lý kéo bản đồ
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO

# Kích thước thế giới và giới hạn camera
var world_size: Vector2 = Vector2(5000, 4200)  # Kích thước bản đồ mới
var map_bounds: Rect2  # Giới hạn bản đồ
var padding: float = 500.0  # Khoảng đệm cho phép camera vượt rìa một chút

# Tham chiếu đến Player
@onready var player = get_node("/root/Ground/Player")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	map_camera.enabled = false
	
	# Tính toán initial_zoom
	var screen_size = get_viewport_rect().size
	var zoom_factor = world_size / screen_size
	var max_zoom_factor = max(zoom_factor.x, zoom_factor.y)
	var initial_zoom = Vector2(1 / max_zoom_factor, 1 / max_zoom_factor)
	
	if initial_zoom.x < min_zoom:
		initial_zoom = Vector2(min_zoom, min_zoom)
	
	map_camera.zoom = initial_zoom
	
	# Xác định giới hạn bản đồ với padding
	map_bounds = Rect2(Vector2(-padding, -padding), world_size + Vector2(padding * 2, padding * 2))

func toggle_map():
	is_active = !is_active
	if is_active:
		show()
		map_camera.enabled = true
		map_camera.make_current()
		get_tree().paused = true
		
		var ground_node = get_node_or_null("/root/Ground")

	else:
		hide()
		map_camera.enabled = false
		var default_camera = get_viewport().get_camera_2d()
		if default_camera and default_camera != map_camera:
			default_camera.make_current()
		get_tree().paused = false
		
		var ground_node = get_node_or_null("/root/Ground")

func _input(event):
	if event.is_action_pressed("ui_map"):
		toggle_map()
	
	if is_active:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				zoom_at_point(zoom_speed, event.position)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				zoom_at_point(-zoom_speed, event.position)
			elif event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					is_dragging = true
					drag_start_pos = event.position
				else:
					is_dragging = false
		
		if event is InputEventMouseMotion and is_dragging:
			var drag_delta = drag_start_pos - event.position
			map_camera.global_position += drag_delta / map_camera.zoom
			drag_start_pos = event.position
			clamp_camera_position()
		
		if event.is_action_pressed("ui_select"):
			if player:
				center_on_player()


func center_on_player():
	map_camera.global_position = player.global_position
	clamp_camera_position()

func zoom_at_point(zoom_change: float, mouse_pos: Vector2):
	var old_zoom = map_camera.zoom
	var new_zoom = old_zoom + Vector2(zoom_change, zoom_change)
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	
	var mouse_world_pos = map_camera.global_position + (mouse_pos - get_viewport_rect().size / 2) / old_zoom
	var zoom_factor = old_zoom / new_zoom
	var new_pos = mouse_world_pos - (mouse_world_pos - map_camera.global_position) * zoom_factor
	
	map_camera.zoom = new_zoom
	map_camera.global_position = new_pos
	clamp_camera_position()

func clamp_camera_position():
	# Tính toán kích thước khung nhìn dựa trên zoom
	var viewport_size = get_viewport_rect().size / map_camera.zoom
	var half_viewport = viewport_size / 2
	
	# Giới hạn vị trí camera với padding
	var min_pos = map_bounds.position + half_viewport
	var max_pos = map_bounds.end - half_viewport
	
	# Kẹp vị trí camera
	map_camera.global_position.x = clamp(map_camera.global_position.x, min_pos.x, max_pos.x)
	map_camera.global_position.y = clamp(map_camera.global_position.y, min_pos.y, max_pos.y)
