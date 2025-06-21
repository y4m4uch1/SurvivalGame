extends CanvasLayer

var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
var item_data = item_db.get_item_data()

@onready var player = get_tree().get_root().get_node("Ground/Player")
@onready var buy_button = $ColorRect/BuyButton
@onready var item_list = $ColorRect/ScrollContainer/VBoxContainer
@onready var grid_container = $ColorRect/GridContainer

var selected_item: String = ""  # Track selected item

var trader_recipes = {
	"TreeLog": {
		"result": {"name": "TreeLog", "quantity": 3},
		"requirements": [
			{"name": "Coin", "quantity": 1},
		],
	},
	"Rock": {
		"result": {"name": "Rock", "quantity": 3},
		"requirements": [
			{"name": "Coin", "quantity": 1},
		],
	},
	"Fiber": {
		"result": {"name": "Fiber", "quantity": 3},
		"requirements": [
			{"name": "Coin", "quantity": 1},
		],
	},
	"Leather": {
		"result": {"name": "Leather", "quantity": 1},
		"requirements": [
			{"name": "Coin", "quantity": 2},
		],
	},
	"SlimeGel": {
		"result": {"name": "SlimeGel", "quantity": 1},
		"requirements": [
			{"name": "Coin", "quantity": 2},
		],
	},
	"Carrot": {
		"result": {"name": "Carrot", "quantity": 1},
		"requirements": [
			{"name": "Coin", "quantity": 4},
		],
	},
	"CarrotSeed": {
		"result": {"name": "CarrotSeed", "quantity": 5},
		"requirements": [
			{"name": "Coin", "quantity": 6},
		],
	},
	"RawMeat": {
		"result": {"name": "RawMeat", "quantity": 1},
		"requirements": [
			{"name": "Coin", "quantity": 5},
		],
	},
	"Bandage": {
		"result": {"name": "Bandage", "quantity": 1},
		"requirements": [
			{"name": "Coin", "quantity": 5},
		],
	},
	"RedFlower": {
		"result": {"name": "RedFlower", "quantity": 1},
		"requirements": [
			{"name": "Coin", "quantity": 1},
		],
	},
	"Mud": {
		"result": {"name": "Mud", "quantity": 1},
		"requirements": [
			{"name": "Coin", "quantity": 3},
		],
	},
	"Bronze": {
		"result": {"name": "Bronze", "quantity": 1},
		"requirements": [
			{"name": "Coin", "quantity": 3},
		],
	},
	"Silver": {
		"result": {"name": "Silver", "quantity": 1},
		"requirements": [
			{"name": "Coin", "quantity": 4},
		],
	},
	"Coin": {
		"result": {"name": "Coin", "quantity": 1},
		"requirements": [
			{"name": "SlimeGel", "quantity": 10},
		],
	},
}
func _ready():
	# Clear previous items
	for child in item_list.get_children():
		child.queue_free()
	for child in grid_container.get_children():
		child.queue_free()

	# Populate item list
	for item_name in trader_recipes.keys():
		var button = Button.new()
		button.text = item_name
		button.pressed.connect(_on_item_button_pressed.bind(item_name))
		item_list.add_child(button)

	# Connect buy button
	buy_button.pressed.connect(_on_buy_button_pressed)

func _on_item_button_pressed(item_name: String):
	selected_item = item_name
	# Clear previous grid content
	for child in grid_container.get_children():
		child.queue_free()
	
	var recipe = trader_recipes[item_name]
	
	# Display result item with image
	var result_container = HBoxContainer.new()
	var result_texture = TextureRect.new()
	var result_label = Label.new()
	
	# Find the category of the item in item_data
	var item_category = ""
	for category in item_data.keys():
		if item_name in item_data[category]:
			item_category = category
			break
	
	# Load texture if available
	if item_category and "texture" in item_data[item_category][item_name]:
		result_texture.texture = load(item_data[item_category][item_name]["texture"])
		result_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		result_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		result_texture.custom_minimum_size = Vector2(32, 32)  # Adjust size as needed
	
	result_label.text = recipe["result"]["name"] + " x" + str(recipe["result"]["quantity"])
	
	result_container.add_child(result_texture)
	result_container.add_child(result_label)
	grid_container.add_child(result_container)
	
	# Display requirements with images
	for req in recipe["requirements"]:
		var req_container = HBoxContainer.new()
		var req_texture = TextureRect.new()
		var req_label = Label.new()
		
		# Find the category of the required item
		var req_category = ""
		for category in item_data.keys():
			if req["name"] in item_data[category]:
				req_category = category
				break
		
		# Load texture if available
		if req_category and "texture" in item_data[req_category][req["name"]]:
			req_texture.texture = load(item_data[req_category][req["name"]]["texture"])
			req_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			req_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			req_texture.custom_minimum_size = Vector2(32, 32)  # Adjust size as needed
		
		req_label.text = req["name"] + " x" + str(req["quantity"])
		
		req_container.add_child(req_texture)
		req_container.add_child(req_label)
		grid_container.add_child(req_container)

func _on_buy_button_pressed():
	if selected_item == "":
		show_notification("Please select an item to buy!")
		return
	
	if try_buy_item(selected_item):
		show_notification("Bought " + selected_item + "!")
	else:
		show_notification("Not enough Coins or inventory full!")

func try_buy_item(item_name: String) -> bool:
	var recipe = trader_recipes[item_name]
	var requirements = recipe["requirements"]
	var result = recipe["result"]

	# Check if player has enough Coins
	for req in requirements:
		var has_enough = false
		for slot in player.inventory:
			if slot["name"] == req["name"] and slot["quantity"] >= req["quantity"]:
				has_enough = true
				slot["quantity"] -= req["quantity"]
				if slot["quantity"] == 0:
					player.inventory.erase(slot)
				break
		if not has_enough:
			return false

	# Add item to player inventory
	for i in range(result["quantity"]):
		if not player.add_to_inventory(result["name"]):
			show_notification("Inventory full!")
			return false

	# Update inventory UI if open
	if player.inventory_ui and player.inventory_ui.visible:
		player.inventory_ui.update_inventory()
	return true

func show_notification(message: String, duration: float = 2.0):
	if player.notification_label:
		player.notification_label.text = message
		var timer = Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "_clear_notification"))
		add_child(timer)
		timer.start()

func _clear_notification():
	if player.notification_label:
		player.notification_label.text = ""
