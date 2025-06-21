extends StaticBody2D

@onready var area_2d: Area2D = $Area2D
var player_in_range: bool = false

func _ready():
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("ui_interact"):
		var main_node = get_tree().get_root().get_node("Ground")
		# Check if the World is visible (player is in World) or CaveWorld is visible (player is in CaveWorld)
		if main_node.get_node("World").visible:
			enter_cave()
		else:
			exit_cave()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		# Show different notifications based on context
		var main_node = get_tree().get_root().get_node("Ground")
		if main_node.get_node("World").visible:
			body.show_notification("Press E to enter the cave", 2.0)
		else:
			body.show_notification("Press E to exit the cave", 2.0)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		body._clear_notification()

func enter_cave():
	# Call the main script's enter_cave function, passing the position of this entrance
	get_tree().get_root().get_node("Ground").enter_cave(position)
	# Notify the spawner that this CaveEntrance is being removed
	var spawner = get_parent()
	if spawner and spawner.has_method("on_cave_entrance_removed"):
		spawner.on_cave_entrance_removed(self)
	# Remove this CaveEntrance
	queue_free()

func exit_cave():
	# Call the main script's exit_cave function
	get_tree().get_root().get_node("Ground").exit_cave()
