extends StaticBody2D

@onready var trader_ui = get_node("/root/Ground/TraderUI")  # Reference to TraderUI
var player_nearby: bool = false  # Track if player is in range
@onready var hello_audio = $HelloSound  # Tham chiếu đến AudioStreamPlayer

func _ready():
	add_to_group("trader")
	# Connect Area2D signals
	$Area2D.connect("body_entered", Callable(self, "_on_body_entered"))
	$Area2D.connect("body_exited", Callable(self, "_on_body_exited"))
	# Ensure TraderUI is hidden initially
	if trader_ui:
		trader_ui.visible = false

func _input(event):
	# Handle "E" key press to toggle TraderUI
	if event.is_action_pressed("ui_interact") and player_nearby:
		if trader_ui:
			trader_ui.visible = !trader_ui.visible
			if trader_ui.visible:
				# Refresh TraderUI by calling its _ready() directly
				trader_ui._ready()
				if hello_audio:
					hello_audio.play()
				
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if trader_ui:
			trader_ui.visible = false  # Hide UI when player leaves
