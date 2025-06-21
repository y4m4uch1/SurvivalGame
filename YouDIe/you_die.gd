extends CanvasLayer

func _ready():
	$ColorRect/Button.pressed.connect(_on_main_menu_button_pressed)

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://GUI/GameMenu/GameMenu.tscn")
