extends StaticBody2D

@export var growth_days: int = 4  # Number of days required for growth (can be adjusted in editor)
var planting_day: int = 0  # Day the CarrotFarm was planted
var player_in_range: bool = false  # Check if player is in range
var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()  # Load item data
var detection_area: Area2D  # Reference to Area2D for player detection
@onready var day_night_cycle = get_node("/root/Ground/World/DayNightWeather")  # Corrected path to DayNightCycle

func _ready():
	# Initialize planting_day from ItemDatabase if available
	if "Structure" in item_data and "CarrotFarm" in item_data["Structure"] and "planting_day" in item_data["Structure"]["CarrotFarm"]:
		planting_day = item_data["Structure"]["CarrotFarm"]["planting_day"]
	else:
		planting_day = day_night_cycle.current_day if day_night_cycle else 0
	
	# Create Area2D for player detection if not present in scene
	if not has_node("DetectionArea"):
		detection_area = Area2D.new()
		var collision_shape = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = 20  # Detection range (adjustable)
		collision_shape.shape = circle_shape
		detection_area.add_child(collision_shape)
		detection_area.name = "DetectionArea"
		add_child(detection_area)
	else:
		detection_area = $DetectionArea
	
	# Connect signals for Area2D
	detection_area.connect("body_entered", Callable(self, "_on_body_entered"))
	detection_area.connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _input(event: InputEvent) -> void:
	# Harvest CarrotFarm when interaction key is pressed and player is in range
	if event.is_action_pressed("ui_interact") and player_in_range:
		harvest_carrot_farm()

func harvest_carrot_farm() -> void:
	var player = get_tree().root.get_node("Ground/Player")
	if not player or not day_night_cycle:
		return
	
	# Check if enough days have passed
	var current_day = day_night_cycle.current_day
	if current_day < planting_day + growth_days:
		var days_remaining = (planting_day + growth_days) - current_day
		player.show_notification("CarrotFarm not ready! Days remaining: " + str(days_remaining))
		return
	
	# Get harvest items from ItemDatabase
	var harvest_items = item_data["Structure"]["CarrotFarm"]["harvest_items"]
	var ground_node = get_tree().root.get_node("Ground")
	if not ground_node:
		return
	
	# Create harvested items
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	for item_name in harvest_items.keys():
		var quantity = harvest_items[item_name]
		for i in range(quantity):
			var dropped_item = item_scene.instantiate()
			dropped_item.item_name = item_name
			dropped_item.position = global_position + Vector2(randi_range(-5, 5), randi_range(-5, 5))
			ground_node.add_child(dropped_item)
	
	# Remove CarrotFarm from player's placed_structures
	var tile_pos = Vector2(
		global_position.x / 16.0,  # Assuming TILE_SIZE = 16.0
		global_position.y / 16.0
	)
	for i in range(player.placed_structures.size()):
		var structure = player.placed_structures[i]
		if (structure["structure_name"] == "CarrotFarm" and
			abs(structure["tile_position"]["x"] - tile_pos.x) < 0.5 and
			abs(structure["tile_position"]["y"] - tile_pos.y) < 0.5):
			player.placed_structures.remove_at(i)
			break
	
	# Remove CarrotFarm from scene
	queue_free()
	player.show_notification("Harvested CarrotFarm!")

# Function to save planting_day when saving game
func get_planting_day() -> int:
	return planting_day

# Function to restore planting_day when loading game
func set_planting_day(day: int) -> void:
	planting_day = day
