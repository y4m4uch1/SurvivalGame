extends CanvasLayer

@onready var player = get_node("/root/Ground/Player")
@onready var day_night_cycle = get_node("/root/Ground/World/DayNightWeather")
@onready var tilemap = get_node("/root/Ground/World")  # Reference to the TileMap node

# Tham chiếu đến các UI khác
@onready var inventory_ui = get_node_or_null("/root/Ground/InventoryUI")
@onready var crafting_ui = get_node_or_null("/root/Ground/CraftingUI")
@onready var map_view = get_node_or_null("/root/Ground/MapView")
@onready var chest_ui = get_node_or_null("/root/Ground/ChestUI")
@onready var trader_ui = get_node_or_null("/root/Ground/TraderUI")

# Kích thước tile (pixel)
const TILE_SIZE: float = 16.0
const MAP_WIDTH: int = 300
const MAP_HEIGHT: int = 250

var entity_spawners: Array = []
var setting_ui_instance = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	find_entity_spawners()
	$VBoxContainer/btnSave.pressed.connect(_on_save_pressed)
	$VBoxContainer/btnSetting.pressed.connect(_on_setting_pressed)
	$VBoxContainer/btnMainMenu.pressed.connect(_on_main_menu_pressed) 
	$VBoxContainer/btnQuit.pressed.connect(_on_quit_pressed) 
	hide()

func find_entity_spawners():
	entity_spawners.clear()
	var root = get_tree().root
	find_spawners_recursive(root)

func find_spawners_recursive(node: Node):
	var script = node.get_script()
	if script and script is GDScript:
		var script_path = script.resource_path
		if script_path == "res://World/Scripts/spawnObj.gd" or script_path == "res://World/Enemy/Slime/slime_spawner.gd" or script_path == "res://World/Cow/cow_spawner.gd" or script_path == "res://World/Cave/cave_entrance_respawn.gd" :
			entity_spawners.append(node)
	for child in node.get_children():
		find_spawners_recursive(child)
		
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func _on_main_menu_pressed():
	# Lưu trò chơi trước khi chuyển scene (tùy chọn)
	save_game()
	# Unpause trò chơi trước khi chuyển
	get_tree().paused = false
	# Chuyển sang scene Main Menu
	get_tree().change_scene_to_file("res://GUI/GameMenu/GameMenu.tscn")  # Thay đường dẫn nếu cần

func _on_quit_pressed():
	# Lưu trò chơi trước khi thoát (tùy chọn)
	save_game()
	# Unpause trò chơi trước khi thoát
	get_tree().paused = false
	# Thoát chương trình
	get_tree().quit()

func _on_setting_pressed():
	if not setting_ui_instance:
		var setting_ui_scene = preload("res://GUI/Setting/SettingUI.tscn")
		setting_ui_instance = setting_ui_scene.instantiate()
		setting_ui_instance.connect("settings_closed", Callable(self, "_on_settings_closed"))
		add_child(setting_ui_instance)
	setting_ui_instance.visible = true
	hide()  # Ẩn menu tạm dừng

func _on_settings_closed():
	if setting_ui_instance:
		setting_ui_instance.queue_free()
		setting_ui_instance = null
	show()  # Hiển thị lại menu tạm dừng
	get_tree().paused = true

func toggle_pause():
	if inventory_ui:
		inventory_ui.visible = false
	if crafting_ui:
		crafting_ui.visible = false
	if map_view:
		map_view.is_active = false
		map_view.hide()
		map_view.map_camera.enabled = false
	if chest_ui:
		chest_ui.visible = false
	if trader_ui:
		trader_ui.visible = false
	visible = !visible
	get_tree().paused = visible
	
func _on_save_pressed():
	save_game()
	hide()
	get_tree().paused = false

func _on_load_pressed():
	load_game()
	hide()
	get_tree().paused = false

func save_game():
	var main_node = get_tree().get_root().get_node("Ground")
	if main_node and not main_node.get_node("World").visible:
		player.show_notification("Cannot save while in the cave!")
		return
	
	if not player:
		return

	var save_data = {}
	var all_entities_data = []
	var all_respawn_queues = []

	for spawner in entity_spawners:
		var entities = spawner.get_spawned_entities()
		for entity in entities:
			var instance = entity["instance"]
			if instance and is_instance_valid(instance):
				# Chuyển đổi global_position sang tile_position
				var tile_pos = Vector2(
					instance.global_position.x / TILE_SIZE,
					instance.global_position.y / TILE_SIZE
				)
				# Giới hạn trong phạm vi bản đồ
				tile_pos.x = clamp(tile_pos.x, 0, MAP_WIDTH - 1)
				tile_pos.y = clamp(tile_pos.y, 0, MAP_HEIGHT - 1)
				var item_name = entity["item_name"] if "item_name" in entity else ""
				var can_respawn = entity["can_respawn"] if "can_respawn" in entity else false
				var health = instance.current_health if "current_health" in instance else -1
				all_entities_data.append({
					"spawner_path": spawner.get_path(),
					"entity_data": {
						"type": entity["type"],
						"tile_position": {"x": tile_pos.x, "y": tile_pos.y},
						"visible": entity["visible"],
						"name": entity["name"],
						"item_name": item_name,
						"can_respawn": can_respawn,
						"health": health
					}
				})
		if spawner.has_method("get_respawn_queue"):
			var respawn_queue = spawner.get_respawn_queue()
			for item in respawn_queue:
				var entity_data = item["entity_data"]
				var updated_entity_data = {
					"type": entity_data["type"],
					"tile_position": entity_data["tile_position"],
					"can_respawn": entity_data["can_respawn"],
					"name": entity_data["name"]
				}
				if "item_name" in entity_data:
					updated_entity_data["item_name"] = entity_data["item_name"]
				else:
					updated_entity_data["item_name"] = ""
				all_respawn_queues.append({
					"spawner_path": spawner.get_path(),
					"respawn_data": {
						"entity_data": updated_entity_data,
						"time_remaining": item["time_remaining"]
					}
				})

	var dropped_items_data = []
	var chests_data = []
	var ground_node = get_tree().root.get_node("Ground")
	var other_container = get_tree().root.get_node("Ground/World/OtherContainer")
	if ground_node:
		for child in ground_node.get_children():
			if child.get_script() and child.get_script().resource_path == "res://GUI/Inventory/item.gd":
				var tile_pos = Vector2(
					child.global_position.x / TILE_SIZE,
					child.global_position.y / TILE_SIZE
				)
				tile_pos.x = clamp(tile_pos.x, 0, MAP_WIDTH - 1)
				tile_pos.y = clamp(tile_pos.y, 0, MAP_HEIGHT - 1)
				var item_data = {
					"type": "res://GUI/Inventory/Item.tscn",
					"tile_position": {"x": tile_pos.x, "y": tile_pos.y},
					"item_name": child.item_name,
					"current_durability": child.get_meta("current_durability", -1)
				}
				dropped_items_data.append(item_data)

		for structure in player.placed_structures:
			if structure["structure_name"] in ["WoodenChest", "IronChest"]:
				var chest_inventory = []
				var structure_tile_pos = Vector2(
					structure["tile_position"]["x"],
					structure["tile_position"]["y"]
				)
				structure_tile_pos.x = clamp(structure_tile_pos.x, 0, MAP_WIDTH - 1)
				structure_tile_pos.y = clamp(structure_tile_pos.y, 0, MAP_HEIGHT - 1)
				var structure_world_pos = structure_tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
				
				var found = false
				for child in other_container.get_children():
					if child is Node2D and child.get_node_or_null("StaticBody2D"):
						var static_body = child.get_node("StaticBody2D")
						if static_body.has_meta("structure_name") and static_body.get_meta("structure_name") == structure["structure_name"] and \
						   child.global_position.distance_to(structure_world_pos) < TILE_SIZE:
							if static_body.has_meta("chest_inventory"):
								chest_inventory = static_body.get_meta("chest_inventory").duplicate(true)
							else:
								var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
								var max_slots = item_db.get_item_data()["Structure"][structure["structure_name"]]["slot"]
								chest_inventory.resize(max_slots)
								for i in range(max_slots):
									chest_inventory[i] = {}
								static_body.set_meta("chest_inventory", chest_inventory.duplicate(true))
							found = true
							break
				
				if not found:
					var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
					var max_slots = item_db.get_item_data()["Structure"][structure["structure_name"]]["slot"]
					chest_inventory.resize(max_slots)
					for i in range(max_slots):
						chest_inventory[i] = {}
				
				var chest_data = {
					"structure_name": structure["structure_name"],
					"tile_position": {"x": structure_tile_pos.x, "y": structure_tile_pos.y},
					"inventory": chest_inventory,
					"rotation_degrees": structure["metadata"].get("rotation_degrees", 0)
				}
				chests_data.append(chest_data)

	var placed_structures_data = []
	var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
	var item_data = item_db.get_item_data()
	for structure in player.placed_structures:
		var tile_pos = Vector2(
			structure["tile_position"]["x"],
			structure["tile_position"]["y"]
		)
		tile_pos.x = clamp(tile_pos.x, 0, MAP_WIDTH - 1)
		tile_pos.y = clamp(tile_pos.y, 0, MAP_HEIGHT - 1)
		var collision_data = structure["metadata"]["collision_data"]
		var normalized_collision_data = {
			"type": collision_data["type"]
		}
		if collision_data["type"] == "Rectangle":
			normalized_collision_data["size"] = {
				"x": collision_data["size"].x,
				"y": collision_data["size"].y
			}
		elif collision_data["type"] == "Circle":
			normalized_collision_data["radius"] = collision_data["radius"]
	
		var normalized_structure = {
			"structure_name": structure["structure_name"],
			"tile_position": {"x": tile_pos.x, "y": tile_pos.y},
			"metadata": {
			"scale": structure["metadata"]["scale"],
			"collision_type": structure["metadata"]["collision_type"],
			"collision_data": normalized_collision_data,
			"rotation_degrees": structure["metadata"]["rotation_degrees"]
			}
		}
		if item_data["Structure"][structure["structure_name"]].has("scene_path"):
			normalized_structure["scene_path"] = item_data["Structure"][structure["structure_name"]]["scene_path"]
		if structure["structure_name"] == "CarrotFarm" and structure["metadata"].has("planting_day"):
			normalized_structure["metadata"]["planting_day"] = structure["metadata"]["planting_day"]
		# Lưu health nếu structure có health
		if structure["structure_name"] in item_data["Structure"] and item_data["Structure"][structure["structure_name"]].has("health"):
			var structure_world_pos = tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
			var health = item_data["Structure"][structure["structure_name"]]["health"]  # Giá trị mặc định
			# Tìm instance trong ground_node
			for child in other_container.get_children():
				if child is StaticBody2D and child.has_meta("structure_name") and \
				   child.get_meta("structure_name") == structure["structure_name"] and \
				   child.global_position.distance_to(structure_world_pos) < TILE_SIZE:
					health = child.get_meta("health", health) if child.has_meta("health") else child.current_health if "current_health" in child else health
					break
			normalized_structure["metadata"]["health"] = health
		
		placed_structures_data.append(normalized_structure)

	var day_night_state = day_night_cycle.get_day_night_state()

	var tilemap_data = {}
	if tilemap:
		var tiles = []
		for x in range(MAP_WIDTH):
			for y in range(MAP_HEIGHT):
				var cell = tilemap.get_cell_atlas_coords(0, Vector2i(x, y))
				if cell != Vector2i(-1, -1):
					tiles.append({
						"x": x,
						"y": y,
						"atlas_coords": {"x": cell.x, "y": cell.y},
						"source_id": tilemap.get_cell_source_id(0, Vector2i(x, y))
					})
		tilemap_data["tiles"] = tiles

	var player_tile_pos = Vector2(
		player.global_position.x / TILE_SIZE,
		player.global_position.y / TILE_SIZE
	)
	player_tile_pos.x = clamp(player_tile_pos.x, 0, MAP_WIDTH - 1)
	player_tile_pos.y = clamp(player_tile_pos.y, 0, MAP_HEIGHT - 1)

	save_data["player"] = {
		"tile_position": {"x": player_tile_pos.x, "y": player_tile_pos.y},
		"health": player.health,
		"hunger": player.hunger,
		"thirst": player.thirst,
		"inventory": player.inventory,
		"equipment": player.equipment,
		"speed": player.speed,
		"defense": player.defense,
		"attack_damage": player.attack_damage,
		"placed_structures": placed_structures_data
	}
	save_data["entities"] = all_entities_data
	save_data["dropped_items"] = dropped_items_data
	save_data["respawn_queues"] = all_respawn_queues
	save_data["chests"] = chests_data
	save_data["day_night_cycle"] = day_night_state

	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "  ", true))
		file.close()
	
	var tilemap_file = FileAccess.open("user://tilemap_data.save", FileAccess.WRITE)
	if tilemap_file:
		tilemap_file.store_string(JSON.stringify(tilemap_data, "  ", true))
		tilemap_file.close()
	
	player.show_notification("Game Saved!")

func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		if player:
			player.show_notification("No save file found!")
		return
	
	var file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if file:
		var save_data = JSON.parse_string(file.get_as_text())
		file.close()
		
		if not player:
			return

		if FileAccess.file_exists("user://tilemap_data.save"):
			var tilemap_file = FileAccess.open("user://tilemap_data.save", FileAccess.READ)
			if tilemap_file:
				var tilemap_data = JSON.parse_string(tilemap_file.get_as_text())
				tilemap_file.close()
				if tilemap and tilemap.has_method("load_tilemap"):
					tilemap.load_tilemap(tilemap_data)
				else:
					player.show_notification("Failed to load tilemap: TileMap node not found or missing load_tilemap method")
			else:
				player.show_notification("Failed to open tilemap save file")
		else:
			player.show_notification("No tilemap save file found, generating new tilemap")
			if tilemap and tilemap.has_method("generate_tilemap"):
				tilemap.generate_tilemap()

		var player_tile_pos = Vector2(save_data["player"]["tile_position"]["x"], save_data["player"]["tile_position"]["y"])
		player_tile_pos.x = clamp(player_tile_pos.x, 0, MAP_WIDTH - 1)
		player_tile_pos.y = clamp(player_tile_pos.y, 0, MAP_HEIGHT - 1)
		player.global_position = player_tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
		player.health = save_data["player"]["health"]
		player.hunger = save_data["player"]["hunger"]
		player.thirst = save_data["player"]["thirst"]
		player.inventory = save_data["player"]["inventory"]
		player.equipment = save_data["player"]["equipment"]
		player.speed = save_data["player"]["speed"]
		player.defense = save_data["player"]["defense"]
		player.attack_damage = save_data["player"]["attack_damage"]
		player.placed_structures = save_data["player"]["placed_structures"] if "placed_structures" in save_data["player"] else []
		
		player.update_health_label()
		player.update_hunger_label()
		player.update_thirst_label()
		player.health_bar.value = player.health
		player.hunger_bar.value = player.hunger
		player.thirst_bar.value = player.thirst
		player.update_stats()
		player.update_visuals()
		if player.inventory_ui and player.inventory_ui.visible:
			player.inventory_ui.update_inventory()
		
		find_entity_spawners()
		for spawner in entity_spawners:
			for child in spawner.get_children():
				child.queue_free()
			spawner.spawned_entities.clear()
			if "respawn_queue" in spawner:
				spawner.respawn_queue.clear()
			# Khôi phục timer cho SlimeSpawner
			if spawner.get_script().resource_path == "res://World/Enemy/Slime/slime_spawner.gd" and spawner.has_method("initialize_timer"):
				spawner.initialize_timer()
		
		var ground_node = get_tree().root.get_node("Ground")
		var other_container = get_tree().root.get_node("Ground/World/OtherContainer")
		if ground_node:
			for child in ground_node.get_children():
				if (child.get_script() and child.get_script().resource_path == "res://GUI/Inventory/Item.gd") or \
				   (child.get_node_or_null("StaticBody2D")):
					child.queue_free()

			for entity in save_data["entities"]:
				var spawner_path = entity["spawner_path"]
				var entity_data = entity["entity_data"]
				var spawner = get_node_or_null(spawner_path)
				if spawner:
					var instance = load(entity_data["type"]).instantiate()
					var tile_pos = Vector2(entity_data["tile_position"]["x"], entity_data["tile_position"]["y"])
					tile_pos.x = clamp(tile_pos.x, 0, MAP_WIDTH - 1)
					tile_pos.y = clamp(tile_pos.y, 0, MAP_HEIGHT - 1)
					instance.position = tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
					instance.visible = entity_data["visible"]
# Thiết lập health trước khi thêm vào cây cảnh
					if "health" in entity_data and entity_data["health"] >= 0 and instance.has_method("set_saved_health"):
						instance.set_saved_health(entity_data["health"])
					elif "health" in entity_data and entity_data["health"] >= 0 and "current_health" in instance:
						instance.current_health = entity_data["health"]
					if "item_name" in entity_data and entity_data["type"] == "res://GUI/Inventory/Item.tscn" and entity_data["item_name"] != "":
						instance.item_name = entity_data["item_name"]
					spawner.add_child(instance)
					var new_entity_data = {
						"type": entity_data["type"],
						"tile_position": {"x": tile_pos.x, "y": tile_pos.y},
						"visible": entity_data["visible"],
						"name": instance.name,
						"instance": instance,
						"health": entity_data["health"] if "health" in entity_data else -1
					}
					if spawner.get_script().resource_path == "res://World/Scripts/spawnObj.gd" or spawner.get_script().resource_path == "res://World/Cow/cow_spawner.gd" or spawner.get_script().resource_path == "res://World/Enemy/Slime/slime_spawner.gd" or spawner.get_script().resource_path == "res://World/Cave/cave_entrance_respawn.gd":
						new_entity_data["item_name"] = entity_data["item_name"] if "item_name" in entity_data else ""
						new_entity_data["can_respawn"] = entity_data["can_respawn"] if "can_respawn" in entity_data else false
					spawner.spawned_entities.append(new_entity_data)

			for item in save_data["dropped_items"]:
				var instance = load(item["type"]).instantiate()
				var tile_pos = Vector2(item["tile_position"]["x"], item["tile_position"]["y"])
				tile_pos.x = clamp(tile_pos.x, 0, MAP_WIDTH - 1)
				tile_pos.y = clamp(tile_pos.y, 0, MAP_HEIGHT - 1)
				instance.global_position = tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
				if "item_name" in item:
					instance.item_name = item["item_name"]
				if item["current_durability"] >= 0:
					instance.set_meta("current_durability", item["current_durability"])
				ground_node.add_child(instance)

			var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
			var item_data = item_db.get_item_data()
			var chest_data = load_chest_data()

			for structure in player.placed_structures:
				var structure_name = structure["structure_name"]
				if not structure_name in item_data["Structure"]:
					continue

				var structure_instance = null
				var rotation_degrees = structure["metadata"].get("rotation_degrees", 0)
				if structure.has("scene_path") and ResourceLoader.exists(structure["scene_path"]):
					# Tải instance từ scene nếu có scene_path
					structure_instance = load(structure["scene_path"]).instantiate()
					structure_instance.rotation_degrees = rotation_degrees
				else:
					# Tạo thủ công nếu không có scene_path
					structure_instance = StaticBody2D.new()
					var sprite = Sprite2D.new()
					var texture_path = item_data["Structure"][structure_name]["texture"]
					if ResourceLoader.exists(texture_path):
						sprite.texture = load(texture_path)
					sprite.scale = Vector2(structure["metadata"]["scale"]["x"], structure["metadata"]["scale"]["y"])
					sprite.rotation_degrees = rotation_degrees
					structure_instance.add_child(sprite)

					var collision_shape = CollisionShape2D.new()
					var shape = null
					var shape_data = structure["metadata"]["collision_data"]
					var collision_type = structure["metadata"]["collision_type"]

					if collision_type == "Rectangle":
						shape = RectangleShape2D.new()
						shape.extents = Vector2(shape_data["size"]["x"], shape_data["size"]["y"]) / 2
					elif collision_type == "Circle":
						shape = CircleShape2D.new()
						shape.radius = shape_data["radius"]
					collision_shape.shape = shape
					collision_shape.rotation_degrees = structure["metadata"].get("rotation_degrees", 0)
					structure_instance.add_child(collision_shape)  # Attach directly to structure_instance

					# Set metadata on structure_instance instead of a separate static_body
					structure_instance.set_meta("structure_name", structure_name)
					structure_instance.set_meta("scale", Vector2(structure["metadata"]["scale"]["x"], structure["metadata"]["scale"]["y"]))
					structure_instance.set_meta("collision_type", collision_type)
					structure_instance.set_meta("collision_data", shape_data)
					structure_instance.set_meta("rotation_degrees", structure["metadata"].get("rotation_degrees", 0))

				if structure_name == "CarrotFarm" and structure["metadata"].has("planting_day"):
					if structure_instance.has_method("set_planting_day"):
						structure_instance.call_deferred("set_planting_day", structure["metadata"]["planting_day"])
				
				# Khôi phục health nếu structure có health
				if structure["metadata"].has("health"):
					if structure_instance is StaticBody2D:  # Nếu instance là StaticBody2D (như WoodenSpikes)
						if structure_instance.has_method("set_saved_health"):
							structure_instance.call_deferred("set_saved_health", structure["metadata"]["health"])
						elif "current_health" in structure_instance:
							structure_instance.current_health = structure["metadata"]["health"]
							structure_instance.set_meta("health", structure["metadata"]["health"])
					
				if structure_name in ["WoodenChest", "IronChest"]:
					var structure_tile_pos = Vector2(structure["tile_position"]["x"], structure["tile_position"]["y"])
					structure_tile_pos.x = clamp(structure_tile_pos.x, 0, MAP_WIDTH - 1)
					structure_tile_pos.y = clamp(structure_tile_pos.y, 0, MAP_HEIGHT - 1)
					var structure_world_pos = structure_tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
					var chest_id = str(structure_world_pos.x) + "_" + str(structure_world_pos.y)
					
					if chest_data.has(chest_id):
						var loaded_inventory = chest_data[chest_id]["inventory"]
						var max_slots = item_data["Structure"][structure_name]["slot"]
						if not (loaded_inventory is Array) or loaded_inventory.size() != max_slots:
							loaded_inventory = []
							loaded_inventory.resize(max_slots)
							for i in range(max_slots):
								loaded_inventory[i] = {}
						for i in range(max_slots):
							if not (loaded_inventory[i] is Dictionary):
								loaded_inventory[i] = {}
						if structure_instance and structure_instance.get_node_or_null("StaticBody2D"):
							structure_instance.get_node("StaticBody2D").set_meta("chest_inventory", loaded_inventory.duplicate(true))
					else:
						for chest in save_data["chests"]:
							var saved_tile_pos = Vector2(chest["tile_position"]["x"], chest["tile_position"]["y"])
							var saved_world_pos = saved_tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
							if saved_world_pos.distance_to(structure_world_pos) < TILE_SIZE:
								var loaded_inventory = chest["inventory"]
								var max_slots = item_data["Structure"][structure_name]["slot"]
								if not (loaded_inventory is Array) or loaded_inventory.size() != max_slots:
									loaded_inventory = []
									loaded_inventory.resize(max_slots)
									for i in range(max_slots):
										loaded_inventory[i] = {}
								for i in range(max_slots):
									if not (loaded_inventory[i] is Dictionary):
										loaded_inventory[i] = {}
								if structure_instance and structure_instance.get_node_or_null("StaticBody2D"):
									structure_instance.get_node("StaticBody2D").set_meta("chest_inventory", loaded_inventory.duplicate(true))
								break
								
				var tile_pos = Vector2(structure["tile_position"]["x"], structure["tile_position"]["y"])
				tile_pos.x = clamp(tile_pos.x, 0, MAP_WIDTH - 1)
				tile_pos.y = clamp(tile_pos.y, 0, MAP_HEIGHT - 1)
				structure_instance.global_position = tile_pos * TILE_SIZE + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
				other_container.add_child(structure_instance)

			if "respawn_queues" in save_data:
				for respawn_item in save_data["respawn_queues"]:
					var spawner_path = respawn_item["spawner_path"]
					var respawn_data = respawn_item["respawn_data"]
					var spawner = get_node_or_null(spawner_path)
					if spawner and spawner.has_method("restore_respawn_timer"):
						var entity_data = respawn_data["entity_data"]
						if not "item_name" in entity_data:
							entity_data["item_name"] = ""
						var tile_pos = Vector2(entity_data["tile_position"]["x"], entity_data["tile_position"]["y"])
						tile_pos.x = clamp(tile_pos.x, 0, MAP_WIDTH - 1)
						tile_pos.y = clamp(tile_pos.y, 0, MAP_HEIGHT - 1)
						entity_data["tile_position"] = {"x": tile_pos.x, "y": tile_pos.y}
						spawner.restore_respawn_timer(entity_data, respawn_data["time_remaining"])


			if "day_night_cycle" in save_data:
				day_night_cycle.set_day_night_state(save_data["day_night_cycle"])
		
		player.show_notification("Game Loaded!")

func load_chest_data() -> Dictionary:
	if not FileAccess.file_exists("user://chest_data.save"):
		return {}
	
	var file = FileAccess.open("user://chest_data.save", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		return data if data is Dictionary else {}
	return {}
