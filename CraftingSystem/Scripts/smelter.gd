extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var day_night_cycle = get_node_or_null("/root/Ground/World/DayNightWeather")
@onready var player_camera = get_node_or_null("/root/Ground/Player/Camera2D")
var light: PointLight2D
var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
var item_data = item_db.get_item_data()

# Light properties
var gradient_texture: GradientTexture2D
var light_tween: Tween

func _ready():
	set_meta("structure_name", "Smelter")
	
	# Initialize gradient texture
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 64
	gradient_texture.height = 64
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.fill_from = Vector2(0.5, 0.5)
	gradient_texture.fill_to = Vector2(1, 1)
	
	# Set up PointLight2D
	light = PointLight2D.new()
	light.texture = gradient_texture
	light.energy = 1.5
	light.texture_scale = 2.0
	light.range_layer_min = -1
	light.range_layer_max = 1
	light.color = Color(1.0, 0.5, 0.2, 1.0)
	light.z_index = 1
	light.visible = false
	add_child(light)
	
	# Set up sprite
	if sprite:
		sprite.scale = item_data["Structure"]["Smelter"]["scale"] if item_data["Structure"].has("Smelter") else Vector2(0.09, 0.09)
	
	# Set up light flicker tween
	if light:
		light_tween = create_tween().set_loops()
		light_tween.tween_property(light, "energy", 1.35, 0.5).set_trans(Tween.TRANS_SINE)
		light_tween.tween_property(light, "energy", 1.5, 0.5).set_trans(Tween.TRANS_SINE)
		light_tween.stop()
	
	# Connect day-night signal or use timer
	if day_night_cycle and day_night_cycle.has_signal("day_night_changed"):
		day_night_cycle.connect("day_night_changed", Callable(self, "_update_light_visibility"))
	else:
		var timer = Timer.new()
		timer.wait_time = 15.0
		timer.autostart = true
		timer.connect("timeout", Callable(self, "_update_light_visibility"))
		add_child(timer)
	
	_update_light_visibility()

func _update_light_visibility():
	if light and day_night_cycle:
		var is_on_screen = true
		if player_camera:
			var camera_rect = Rect2(player_camera.global_position - player_camera.get_viewport_rect().size / 2, player_camera.get_viewport_rect().size)
			is_on_screen = camera_rect.has_point(global_position)
		var should_be_visible = !day_night_cycle.is_day and is_on_screen
		if light.visible != should_be_visible:
			light.visible = should_be_visible
			if should_be_visible:
				light_tween.play()
			else:
				light_tween.stop()
	else:
		if light:
			light.visible = false
			light_tween.stop()
