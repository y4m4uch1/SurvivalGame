extends StaticBody2D

@onready var animation_player = $AnimatedSprite2D
@onready var detection_area = $Area2D
@onready var day_night_cycle = get_node_or_null("/root/Ground/World/DayNightWeather")
@onready var main_node = get_tree().get_root().get_node_or_null("Ground")
var light: PointLight2D
var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
var item_data = item_db.get_item_data()

# Light properties
var gradient_texture: GradientTexture2D
var light_tween: Tween

func _ready():
	set_meta("structure_name", "Torch")
	
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
	light.energy = 1.2
	light.texture_scale = 5.5
	light.range_layer_min = -1
	light.range_layer_max = 1
	light.color = Color(1.0, 0.5, 0.2, 1.0)
	light.z_index = 1
	light.visible = false
	add_child(light)
	
	# Disable AnimatedSprite2D processing initially
	if animation_player:
		animation_player.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Connect Area2D signals
	if detection_area:
		detection_area.connect("body_entered", Callable(self, "_on_body_entered"))
		detection_area.connect("body_exited", Callable(self, "_on_body_exited"))
		detection_area.collision_layer = 2
	
	# Set up light flicker tween
	if light:
		light_tween = create_tween().set_loops()
		light_tween.tween_property(light, "energy", 1.1, 0.5).set_trans(Tween.TRANS_SINE)
		light_tween.tween_property(light, "energy", 1.2, 0.5).set_trans(Tween.TRANS_SINE)
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

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		if animation_player:
			animation_player.process_mode = Node.PROCESS_MODE_INHERIT
			animation_player.play("default")

func _on_body_exited(body: Node):
	if body.is_in_group("player"):
		if animation_player:
			animation_player.process_mode = Node.PROCESS_MODE_DISABLED
			animation_player.stop()

func _update_light_visibility():
	if light and main_node:
		# Check if in cave or if it's night
		var is_in_cave = main_node.get_node_or_null("CaveWorld") and main_node.get_node("CaveWorld").visible
		var is_night = day_night_cycle and not day_night_cycle.is_day
		var should_be_visible = is_in_cave or is_night
		
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
