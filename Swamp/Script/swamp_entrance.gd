extends StaticBody2D

@onready var area_2d: Area2D = $Area2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var player_in_range: bool = false

func _ready():
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)
	animated_sprite.stop() # Dừng animation khi khởi tạo để giảm tải CPU

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("ui_interact"):
		var main_node = get_tree().get_root().get_node("Ground")
		if main_node.get_node("World").visible:
			enter_swamp()
		else:
			exit_swamp()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		animated_sprite.play() # Bắt đầu phát animation khi player vào khu vực
		var main_node = get_tree().get_root().get_node("Ground")
		if main_node.get_node("World").visible:
			body.show_notification("Press E to enter the Swamp", 5.0)
		else:
			body.show_notification("Press E to exit the Swamp", 5.0)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		animated_sprite.stop() # Dừng animation khi player rời khu vực
		body._clear_notification()

func enter_swamp():
	get_tree().get_root().get_node("Ground").enter_swamp(position)
	var spawner = get_parent()
	if spawner and spawner.has_method("on_swamp_entrance_removed"):
		spawner.on_cave_entrance_removed(self)
	queue_free()

func exit_swamp():
	get_tree().get_root().get_node("Ground").exit_swamp()
