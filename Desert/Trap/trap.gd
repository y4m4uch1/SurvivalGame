extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var area_2d = $Area2D
@onready var collision_shape = area_2d.get_node("CollisionShape2D")
var warning_polygon: Polygon2D
var player_in_area: Node2D = null
var warning_timer: float = 0.0
var warning_duration: float = 1 
var is_warning: bool = false
var damage: int = 15

func _ready():
	# Initialize warning polygon
	warning_polygon = Polygon2D.new()
	warning_polygon.color = Color(1, 0, 0, 0.3)  # Red with 30% opacity, matching slime's attack circle
	warning_polygon.visible = false
	add_child(warning_polygon)
	update_warning_polygon()

	# Set up collision layers and masks
	collision_layer = 1  # Ensure trap is on layer 1
	collision_mask = 1   # Detect collisions with layer 1
	area_2d.collision_layer = 1
	area_2d.collision_mask = 1

	# Connect Area2D signals
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)

	# Ensure sprite starts at frame 0
	sprite.frame = 0

func _physics_process(delta: float):
	if is_warning and player_in_area:
		warning_timer += delta
		if warning_timer >= warning_duration:
			sprite.frame = 1 
			if player_in_area and player_in_area.has_method("take_damage"):
				player_in_area.take_damage(damage, true)  # Deal 15 damage, ignoring defense
			is_warning = false
			warning_polygon.visible = false
			warning_timer = 0.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = body
		is_warning = true
		warning_timer = 0.0
		warning_polygon.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_area:
		player_in_area = null
		is_warning = false
		warning_polygon.visible = false
		warning_timer = 0.0
		sprite.frame = 0  # Reset to frame 0 when player exits

func update_warning_polygon():
	var shape = collision_shape.shape
	if shape is CircleShape2D:
		var radius = shape.radius * collision_shape.scale.x  # Apply scale to match collision area
		var points = []
		var num_points = 32
		for i in range(num_points + 1):
			var angle = i * 2 * PI / num_points
			var point = Vector2(cos(angle), sin(angle)) * radius
			points.append(point)
		warning_polygon.polygon = points
	elif shape is RectangleShape2D:
		var size = shape.size * collision_shape.scale  # Apply scale to match collision area
		var points = [
			Vector2(-size.x / 2, -size.y / 2),
			Vector2(size.x / 2, -size.y / 2),
			Vector2(size.x / 2, size.y / 2),
			Vector2(-size.x / 2, size.y / 2)
		]
		warning_polygon.polygon = points
	warning_polygon.position = collision_shape.position * collision_shape.scale  # Adjust position based on scaled collision shape
	warning_polygon.scale = Vector2(1, 1)  # No additional scaling
