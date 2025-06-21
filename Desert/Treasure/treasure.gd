extends StaticBody2D

@export var max_health: int = 25  # Health of the treasure chest
var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()  # Load item_data

var current_health: int

var drop_item: Array = [
	{"item_name": "TreeLog", "probability": 0.20},  
	{"item_name": "Iron", "probability": 0.02},  
	{"item_name": "Stone", "probability": 0.20},    
	{"item_name": "Fiber", "probability": 0.20},    
	{"item_name": "Apple", "probability": 0.05},   
	{"item_name": "Carrot", "probability": 0.05}, 
	{"item_name": "RawMeat", "probability": 0.02}, 
	{"item_name": "Copper", "probability": 0.10}, 
	{"item_name": "Tin", "probability": 0.10},    
	{"item_name": "Silver", "probability": 0.03},
	{"item_name": "Bronze", "probability": 0.05},   
	{"item_name": "Gold", "probability": 0.03},     
	{"item_name": "SlimeGel", "probability": 0.20},
	{"item_name": "Sand", "probability": 0.15},     
	{"item_name": "Mud", "probability": 0.15},     
	{"item_name": "Coin", "probability": 0.05},     
	{"item_name": "Leather", "probability": 0.15},
	{"item_name": "Vine", "probability": 0.15},
]

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health -= amount
	# Play the hit sound
	$AudioStreamPlayer2D.play()
	if current_health <= 0:
		break_treasure()

func break_treasure():
	# Determine number of unique items to attempt (1-3)
	var num_items = randi_range(1, 3)
	var ground_node = get_tree().root.get_node("Ground")
	
	if ground_node:
		# Shuffle drop table to randomize selection
		var shuffled_drops = drop_item.duplicate()
		shuffled_drops.shuffle()
		
		# Counter to track how many unique items have been selected
		var items_selected = 0
		var i = 0
		
		# Iterate through shuffled drop table until we select up to num_items
		while i < shuffled_drops.size() and items_selected < num_items:
			var drop = shuffled_drops[i]
			if randf() < drop["probability"]:  # Check if item drops based on its probability
				var quantity = randi_range(1, 3)  # Random quantity 1-3
				for j in range(quantity):
					var item_instance = create_item(drop["item_name"])
					item_instance.position = global_position + Vector2(randi_range(-10, 10), randi_range(-10, 10))
					ground_node.add_child(item_instance)
				items_selected += 1
			i += 1
	
	# Find spawner and remove entity (treasure) from list
	var spawner = find_spawner_for_entity()
	if spawner:
		spawner.remove_entity(self)
	
	queue_free()

func create_item(item_name: String) -> Node2D:
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var item = item_scene.instantiate()
	
	# Assign properties to the item
	item.item_name = item_name
	return item

func find_spawner_for_entity() -> Node:
	var root = get_tree().root
	var spawners = []
	find_spawners_recursive(root, spawners)
	for spawner in spawners:
		for entity_data in spawner.spawned_entities:
			if entity_data["instance"] == self:
				return spawner
	return null

func find_spawners_recursive(node: Node, spawners: Array) -> void:
	if node.get_script() and node.get_script().resource_path == "res://World/Scripts/spawnObj.gd":
		spawners.append(node)
	for child in node.get_children():
		find_spawners_recursive(child, spawners)
