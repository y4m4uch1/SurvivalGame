extends CanvasLayer

var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
var item_data = item_db.get_item_data()

@onready var grid_container = $ColorRect/GridContainer
@onready var grid_container2 = $ColorRect/GridContainer2
@onready var player = get_node("../Player")
@onready var inventory_ui = get_node("../Inventory")

var chest_inventory = []
var max_slots = 0
var max_stack = 10
var chest_type = ""
var chest_node = null  # Tham chiếu đến StaticBody2D của chest
var chest_id = ""  # ID duy nhất để xác định chest
var tile_size = 16.0  # Kích thước tile (pixel)

var is_dragging = false
var dragged_item = {}
var dragged_texture_rect = null
var dragged_from_slot = -1
var dragged_from_inventory_slot = -1  # Theo dõi slot được kéo từ GridContainer2

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func initialize_chest(chest_name: String):
	chest_type = chest_name
	max_slots = item_data["Structure"][chest_name]["slot"]
	chest_inventory.resize(max_slots)
	
	chest_node = player.near_chest_node
	if chest_node:
		# Tính tọa độ tile từ global_position
		var tile_pos = Vector2(
			floor(chest_node.global_position.x / tile_size),
			floor(chest_node.global_position.y / tile_size)
		)
		# Tạo chest_id dựa trên tọa độ tile
		chest_id = str(tile_pos.x) + "_" + str(tile_pos.y)
		
		# Tải dữ liệu từ file hoặc từ metadata
		var chest_data = load_chest_data()
		if chest_data.has(chest_id) and chest_data[chest_id]["inventory"].size() == max_slots:
			chest_inventory = chest_data[chest_id]["inventory"].duplicate(true)
			chest_node.set_meta("chest_inventory", chest_inventory.duplicate(true))
		elif chest_node.has_meta("chest_inventory"):
			chest_inventory = chest_node.get_meta("chest_inventory").duplicate(true)
		else:
			for i in range(max_slots):
				chest_inventory[i] = {}
			chest_node.set_meta("chest_inventory", chest_inventory.duplicate(true))
			save_chest_data()  # Lưu dữ liệu khởi tạo
	else:
		for i in range(max_slots):
			chest_inventory[i] = {}
	
	update_chest_ui()
	if inventory_ui and inventory_ui.visible:
		inventory_ui.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:  # Đóng ChestUI khi nhấn ESC
		close_chest()
		return

	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var drop_position = get_viewport().get_mouse_position()
		var target_slot = get_slot_at_position(drop_position)
		var target_inventory_slot = get_inventory_slot_at_position(drop_position)  # Kiểm tra slot trong GridContainer2
		var inventory_slot = inventory_ui.get_slot_at_position(drop_position) if inventory_ui and inventory_ui.visible else -1

		# Kiểm tra nếu thả vào chính slot nguồn
		if dragged_from_slot >= 0 and target_slot == dragged_from_slot:
			end_drag()
			update_chest_ui()
			return
		if dragged_from_inventory_slot >= 0 and target_inventory_slot == dragged_from_inventory_slot:
			end_drag()
			update_chest_ui()
			return
		
		# Thả vào slot trong chest (từ GridContainer hoặc GridContainer2)
		if target_slot != -1 and target_slot < chest_inventory.size():
			if dragged_from_slot >= 0:  # Kéo từ GridContainer (chest_inventory)
				var temp = chest_inventory[target_slot].duplicate() if not chest_inventory[target_slot].is_empty() else {}
				
				if temp.is_empty():
					chest_inventory[target_slot] = dragged_item.duplicate()
					chest_inventory[dragged_from_slot] = {}
				else:
					if (chest_inventory[target_slot]["name"] == dragged_item["name"] and 
						not chest_inventory[target_slot].has("current_durability") and 
						not dragged_item.has("current_durability")):
						var total_quantity = chest_inventory[target_slot]["quantity"] + dragged_item["quantity"]
						if total_quantity <= max_stack:
							chest_inventory[target_slot]["quantity"] = total_quantity
							chest_inventory[dragged_from_slot] = {}
						else:
							chest_inventory[target_slot]["quantity"] = max_stack
							chest_inventory[dragged_from_slot]["quantity"] = total_quantity - max_stack
					else:
						var empty_slot = -1
						for i in range(chest_inventory.size()):
							if chest_inventory[i].is_empty() and i != dragged_from_slot:
								empty_slot = i
								break
						
						if empty_slot != -1:
							chest_inventory[empty_slot] = temp.duplicate()
							chest_inventory[target_slot] = dragged_item.duplicate()
							chest_inventory[dragged_from_slot] = {}
						else:
							if player.add_to_inventory(temp["name"], temp.get("current_durability", -1)):
								chest_inventory[target_slot] = dragged_item.duplicate()
								chest_inventory[dragged_from_slot] = {}
							else:
								player.show_notification("Cannot move item: Inventory full!")
								end_drag()
								return
				
				update_chest_node()
				save_chest_data()

			elif dragged_from_inventory_slot >= 0:  # Kéo từ GridContainer2 (player.inventory)
				var temp = chest_inventory[target_slot].duplicate() if not chest_inventory[target_slot].is_empty() else {}
				
				if temp.is_empty():
					chest_inventory[target_slot] = dragged_item.duplicate()
					if dragged_from_inventory_slot < player.inventory.size():
						player.inventory[dragged_from_inventory_slot] = {}
					else:
						player.inventory.append({})
				else:
					if (temp["name"] == dragged_item["name"] and 
						not temp.has("current_durability") and 
						not dragged_item.has("current_durability")):
						var total_quantity = temp["quantity"] + dragged_item["quantity"]
						if total_quantity <= max_stack:
							chest_inventory[target_slot]["quantity"] = total_quantity
							if dragged_from_inventory_slot < player.inventory.size():
								player.inventory[dragged_from_inventory_slot] = {}
							else:
								player.inventory.append({})
						else:
							chest_inventory[target_slot]["quantity"] = max_stack
							dragged_item["quantity"] = total_quantity - max_stack
							if dragged_from_inventory_slot < player.inventory.size():
								player.inventory[dragged_from_inventory_slot] = dragged_item.duplicate()
							else:
								player.inventory.append(dragged_item.duplicate())
					else:
						var empty_slot = -1
						for i in range(chest_inventory.size()):
							if chest_inventory[i].is_empty():
								empty_slot = i
								break
						
						if empty_slot != -1:
							chest_inventory[empty_slot] = temp.duplicate()
							chest_inventory[target_slot] = dragged_item.duplicate()
							if dragged_from_inventory_slot < player.inventory.size():
								player.inventory[dragged_from_inventory_slot] = {}
							else:
								player.inventory.append({})
						else:
							player.show_notification("Cannot move item: Chest full!")
							end_drag()
							return
				
				update_chest_node()
				save_chest_data()

		# Thả vào inventory của người chơi (từ GridContainer hoặc GridContainer2)
		elif target_inventory_slot != -1 and target_inventory_slot < player.max_slots:  # Sửa điều kiện
			if dragged_from_slot >= 0:  # Kéo từ GridContainer (chest_inventory)
				var temp = {}
				if target_inventory_slot < player.inventory.size():
					temp = player.inventory[target_inventory_slot].duplicate() if not player.inventory[target_inventory_slot].is_empty() else {}
				
				if temp.is_empty():
					if target_inventory_slot < player.inventory.size():
						player.inventory[target_inventory_slot] = dragged_item.duplicate()
					else:
						player.inventory.append(dragged_item.duplicate())
					chest_inventory[dragged_from_slot] = {}
				else:
					if (temp["name"] == dragged_item["name"] and 
						not temp.has("current_durability") and 
						not dragged_item.has("current_durability")):
						var total_quantity = temp["quantity"] + dragged_item["quantity"]
						if total_quantity <= max_stack:
							player.inventory[target_inventory_slot]["quantity"] = total_quantity
							chest_inventory[dragged_from_slot] = {}
						else:
							player.inventory[target_inventory_slot]["quantity"] = max_stack
							chest_inventory[dragged_from_slot]["quantity"] = total_quantity - max_stack
					else:
						var empty_slot = -1
						for i in range(player.inventory.size()):
							if player.inventory[i].is_empty():
								empty_slot = i
								break
						if empty_slot == -1 and player.inventory.size() < player.max_slots:
							empty_slot = player.inventory.size()
							player.inventory.append({})
						
						if empty_slot != -1:
							player.inventory[empty_slot] = temp.duplicate()
							player.inventory[target_inventory_slot] = dragged_item.duplicate()
							chest_inventory[dragged_from_slot] = {}
						else:
							var chest_empty_slot = -1
							for i in range(chest_inventory.size()):
								if chest_inventory[i].is_empty() and i != dragged_from_slot:
									chest_empty_slot = i
									break
							
							if chest_empty_slot != -1:
								chest_inventory[chest_empty_slot] = temp.duplicate()
								player.inventory[target_inventory_slot] = dragged_item.duplicate()
								chest_inventory[dragged_from_slot] = {}
							else:
								player.show_notification("Cannot move item: Chest and inventory full!")
								end_drag()
								return
				
				update_chest_node()
				save_chest_data()

			elif dragged_from_inventory_slot >= 0:  # Kéo từ GridContainer2 (player.inventory)
				if target_inventory_slot != dragged_from_inventory_slot:
					var temp = {}
					if target_inventory_slot < player.inventory.size():
						temp = player.inventory[target_inventory_slot].duplicate() if not player.inventory[target_inventory_slot].is_empty() else {}
					
					if temp.is_empty():
						if target_inventory_slot < player.inventory.size():
							player.inventory[target_inventory_slot] = dragged_item.duplicate()
						else:
							player.inventory.append(dragged_item.duplicate())
						if dragged_from_inventory_slot < player.inventory.size():
							player.inventory[dragged_from_inventory_slot] = {}
						else:
							player.inventory.append({})
					else:
						if (temp["name"] == dragged_item["name"] and 
							not temp.has("current_durability") and 
							not dragged_item.has("current_durability")):
							var total_quantity = temp["quantity"] + dragged_item["quantity"]
							if total_quantity <= max_stack:
								player.inventory[target_inventory_slot]["quantity"] = total_quantity
								if dragged_from_inventory_slot < player.inventory.size():
									player.inventory[dragged_from_inventory_slot] = {}
								else:
									player.inventory.append({})
							else:
								player.inventory[target_inventory_slot]["quantity"] = max_stack
								dragged_item["quantity"] = total_quantity - max_stack
								if dragged_from_inventory_slot < player.inventory.size():
									player.inventory[dragged_from_inventory_slot] = dragged_item.duplicate()
								else:
									player.inventory.append(dragged_item.duplicate())
						else:
							if target_inventory_slot < player.inventory.size():
								player.inventory[target_inventory_slot] = dragged_item.duplicate()
							else:
								player.inventory.append(dragged_item.duplicate())
							if dragged_from_inventory_slot < player.inventory.size():
								player.inventory[dragged_from_inventory_slot] = temp.duplicate()
							else:
								player.inventory.append(temp.duplicate())

		# Thả vào InventoryUI (nếu đang mở)
		elif inventory_slot != -1 and inventory_slot < player.max_slots:  # Sửa điều kiện
			if dragged_from_slot >= 0:  # Kéo từ GridContainer (chest_inventory)
				var temp = {}
				if inventory_slot < player.inventory.size():
					temp = player.inventory[inventory_slot].duplicate() if not player.inventory[inventory_slot].is_empty() else {}
				
				if temp.is_empty():
					if inventory_slot < player.inventory.size():
						player.inventory[inventory_slot] = dragged_item.duplicate()
					else:
						player.inventory.append(dragged_item.duplicate())
					chest_inventory[dragged_from_slot] = {}
				else:
					if (temp["name"] == dragged_item["name"] and 
						not temp.has("current_durability") and 
						not dragged_item.has("current_durability")):
						var total_quantity = temp["quantity"] + dragged_item["quantity"]
						if total_quantity <= max_stack:
							player.inventory[inventory_slot]["quantity"] = total_quantity
							chest_inventory[dragged_from_slot] = {}
						else:
							player.inventory[inventory_slot]["quantity"] = max_stack
							chest_inventory[dragged_from_slot]["quantity"] = total_quantity - max_stack
					else:
						var empty_slot = -1
						for i in range(player.inventory.size()):
							if player.inventory[i].is_empty():
								empty_slot = i
								break
						if empty_slot == -1 and player.inventory.size() < player.max_slots:
							empty_slot = player.inventory.size()
							player.inventory.append({})
						
						if empty_slot != -1:
							player.inventory[empty_slot] = temp.duplicate()
							player.inventory[inventory_slot] = dragged_item.duplicate()
							chest_inventory[dragged_from_slot] = {}
						else:
							var chest_empty_slot = -1
							for i in range(chest_inventory.size()):
								if chest_inventory[i].is_empty() and i != dragged_from_slot:
									chest_empty_slot = i
									break
							
							if chest_empty_slot != -1:
								chest_inventory[chest_empty_slot] = temp.duplicate()
								player.inventory[inventory_slot] = dragged_item.duplicate()
								chest_inventory[dragged_from_slot] = {}
							else:
								player.show_notification("Cannot move item: Chest and inventory full!")
								end_drag()
								return
				
				update_chest_node()
				save_chest_data()
		
		else:
			end_drag()
			update_chest_ui()
			return
		
		end_drag()
		update_chest_ui()
		if inventory_ui and inventory_ui.visible:
			inventory_ui.update_inventory()


func _process(delta):
	# Đóng chest nếu người chơi đi quá xa
	if visible and chest_node and player:
		var distance = player.global_position.distance_to(chest_node.global_position)
		if distance > 50:  # Khoảng cách tối đa để giữ chest mở
			close_chest()
	
	if is_dragging and dragged_texture_rect:
		dragged_texture_rect.position = get_viewport().get_mouse_position() - dragged_texture_rect.size / 2

func close_chest():
	if visible:
		update_chest_node()
		save_chest_data()  # Lưu dữ liệu chest khi đóng
		visible = false
		player.near_chest_node = null  # Reset tham chiếu đến chest
		chest_node = null
		chest_inventory.clear()
		chest_type = ""
		chest_id = ""

func save_chest_data():
	if not chest_node or chest_id == "":
		return
	
	# Tính tọa độ tile từ global_position
	var tile_pos = Vector2(
		floor(chest_node.global_position.x / tile_size),
		floor(chest_node.global_position.y / tile_size)
	)
	
	# Tải dữ liệu hiện có từ file
	var chest_data = load_chest_data()
	
	# Cập nhật dữ liệu của chest hiện tại
	chest_data[chest_id] = {
		"structure_name": chest_type,
		"tile_position": {
			"x": tile_pos.x,
			"y": tile_pos.y
		},
		"inventory": chest_inventory.duplicate(true),
		"rotation_degrees": chest_node.get_meta("rotation_degrees", 0)
	}
	
	# Lưu dữ liệu vào file
	var file = FileAccess.open("user://chest_data.save", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(chest_data, "  ", true))
		file.close()
		
func load_chest_data() -> Dictionary:
	if not FileAccess.file_exists("user://chest_data.save"):
		return {}
	
	var file = FileAccess.open("user://chest_data.save", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		return data if data is Dictionary else {}
	return {}

func update_chest_ui():
	# Cập nhật GridContainer cho chest_inventory
	for child in grid_container.get_children():
		child.queue_free()

	for i in range(max_slots):
		var item_container = VBoxContainer.new()
		item_container.custom_minimum_size = Vector2(80, 80)

		var texture_rect = TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.custom_minimum_size = Vector2(64, 64)

		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if not chest_inventory[i].is_empty():
			var item = chest_inventory[i]
			var item_name = item["name"]
			var quantity = item["quantity"]

			for category in item_data.keys():
				if item_name in item_data[category]:
					texture_rect.texture = load(item_data[category][item_name]["texture"])
					break

			if item.has("current_durability"):
				label.text = item_name + ": " + str(quantity) + "\nDurability: " + str(item["current_durability"])
			else:
				label.text = item_name + ": " + str(quantity)
		else:
			label.text = "Empty"

		item_container.connect("gui_input", Callable(self, "_on_slot_clicked").bind(i))
		if i == dragged_from_slot:
			item_container.modulate = Color(1, 1, 0, 1)
		else:
			item_container.modulate = Color(1, 1, 1, 1)
		item_container.add_child(texture_rect)
		item_container.add_child(label)
		grid_container.add_child(item_container)

	# Cập nhật GridContainer2 cho player.inventory
	for child in grid_container2.get_children():
		child.queue_free()

	for i in range(player.max_slots):  # Sử dụng player.max_slots thay vì player.inventory.size()
		var item_container = VBoxContainer.new()
		item_container.custom_minimum_size = Vector2(80, 80)

		var texture_rect = TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.custom_minimum_size = Vector2(64, 64)

		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		if i < player.inventory.size() and not player.inventory[i].is_empty():
			var item = player.inventory[i]
			var item_name = item["name"]
			var quantity = item["quantity"]

			for category in item_data.keys():
				if item_name in item_data[category]:
					texture_rect.texture = load(item_data[category][item_name]["texture"])
					break

			if item.has("current_durability"):
				label.text = item_name + ": " + str(quantity) + "\nDurability: " + str(item["current_durability"])
			else:
				label.text = item_name + ": " + str(quantity)
		else:
			label.text = "Empty"

		item_container.connect("gui_input", Callable(self, "_on_inventory_slot_clicked").bind(i))
		if i == dragged_from_inventory_slot:
			item_container.modulate = Color(1, 1, 0, 1)  # Highlight slot đang kéo
		else:
			item_container.modulate = Color(1, 1, 1, 1)
		item_container.add_child(texture_rect)
		item_container.add_child(label)
		grid_container2.add_child(item_container)

func _on_slot_clicked(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not is_dragging:
		if not chest_inventory[slot_index].is_empty():
			is_dragging = true
			dragged_from_slot = slot_index
			dragged_item = chest_inventory[slot_index].duplicate()

			dragged_texture_rect = TextureRect.new()
			dragged_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			dragged_texture_rect.custom_minimum_size = Vector2(64, 64)
			for category in item_data.keys():
				if dragged_item["name"] in item_data[category]:
					dragged_texture_rect.texture = load(item_data[category][dragged_item["name"]]["texture"])
					break
			dragged_texture_rect.modulate = Color(1, 1, 1, 0.7)
			add_child(dragged_texture_rect)

			update_chest_ui()

func move_item_to_slot(item: Dictionary, target_slot: int, source_inventory: Array, target_inventory: Array):
	if target_inventory[target_slot].is_empty():
		target_inventory[target_slot] = item.duplicate()
	else:
		if (target_inventory[target_slot]["name"] == item["name"] and 
			not target_inventory[target_slot].has("current_durability") and 
			not item.has("current_durability")):
			var total_quantity = target_inventory[target_slot]["quantity"] + item["quantity"]
			if total_quantity <= max_stack:
				target_inventory[target_slot]["quantity"] = total_quantity
			else:
				target_inventory[target_slot]["quantity"] = max_stack
				item["quantity"] = total_quantity - max_stack
				for i in range(source_inventory.size()):
					if source_inventory[i].is_empty():
						source_inventory[i] = item.duplicate()
						break
		else:
			var temp = target_inventory[target_slot].duplicate()
			target_inventory[target_slot] = item.duplicate()
			for i in range(source_inventory.size()):
				if source_inventory[i].is_empty():
					source_inventory[i] = temp.duplicate()
					break
	update_chest_node()
	save_chest_data()  # Lưu dữ liệu chest sau khi di chuyển item

func get_slot_at_position(position: Vector2) -> int:
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		var rect = slot.get_global_rect()
		if rect.has_point(position):
			return i
	return -1

func end_drag():
	is_dragging = false
	dragged_item = {}
	dragged_from_slot = -1
	dragged_from_inventory_slot = -1
	if dragged_texture_rect:
		dragged_texture_rect.queue_free()
		dragged_texture_rect = null

func update_chest_node():
	if chest_node:
		chest_node.set_meta("chest_inventory", chest_inventory.duplicate(true))

func _on_inventory_slot_clicked(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not is_dragging:
		if slot_index < player.inventory.size() and not player.inventory[slot_index].is_empty():
			is_dragging = true
			dragged_from_inventory_slot = slot_index
			dragged_item = player.inventory[slot_index].duplicate()

			dragged_texture_rect = TextureRect.new()
			dragged_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			dragged_texture_rect.custom_minimum_size = Vector2(64, 64)
			for category in item_data.keys():
				if dragged_item["name"] in item_data[category]:
					dragged_texture_rect.texture = load(item_data[category][dragged_item["name"]]["texture"])
					break
			dragged_texture_rect.modulate = Color(1, 1, 1, 0.7)
			add_child(dragged_texture_rect)

			update_chest_ui()

func get_inventory_slot_at_position(position: Vector2) -> int:
	for i in range(grid_container2.get_child_count()):
		var slot = grid_container2.get_child(i)
		var rect = slot.get_global_rect()
		if rect.has_point(position):
			return i
	return -1

func destroy_chest(structure_node: Node2D, destroyer_name: String = "Unknown") -> void:
	if not structure_node or not is_instance_valid(structure_node):
		print("Error: Invalid chest node!")
		return
	
	var static_body = null
	for child in structure_node.get_children():
		if child is StaticBody2D and child.has_meta("structure_name"):
			static_body = child
			break
	
	if not static_body:
		print("Error: No valid StaticBody2D found in chest!")
		return
	
	var structure_name = static_body.get_meta("structure_name")
	if structure_name not in ["WoodenChest", "IronChest"]:
		print("Error: Not a chest! Found: ", structure_name)
		return
	
	if chest_node == static_body and visible:
		close_chest()
	
	var chest_inventory_data = static_body.get_meta("chest_inventory", [])
	if not chest_inventory_data.is_empty():
		for item in chest_inventory_data:
			if not item.is_empty():
				drop_item(item, structure_node.global_position)
	
	# Xóa dữ liệu chest khỏi file lưu trữ
	var tile_pos = Vector2(
		floor(structure_node.global_position.x / tile_size),
		floor(structure_node.global_position.y / tile_size)
	)
	var chest_id_to_remove = str(tile_pos.x) + "_" + str(tile_pos.y)
	var chest_data = load_chest_data()
	if chest_data.has(chest_id_to_remove):
		chest_data.erase(chest_id_to_remove)
		save_chest_data_with_data(chest_data)
	
	if player and player.placed_structures:
		for i in range(player.placed_structures.size() - 1, -1, -1):
			var placed = player.placed_structures[i]
			if (abs(placed["tile_position"]["x"] - tile_pos.x) < 0.1 and 
				abs(placed["tile_position"]["y"] - tile_pos.y) < 0.1):
				player.placed_structures.remove_at(i)
				break
	
	if is_instance_valid(structure_node):
		structure_node.queue_free()
		print(destroyer_name, " destroyed chest: ", structure_name, " at ", structure_node.global_position)
	
	if destroyer_name == "Hammer" and player:
		player.show_notification("Chest destroyed with Hammer!")

func drop_item(item: Dictionary, position: Vector2):
	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	var quantity = item.get("quantity", 1)
	for i in range(quantity):
		var dropped_item = item_scene.instantiate()
		dropped_item.item_name = item["name"]
		if item.has("current_durability"):
			dropped_item.set_meta("current_durability", item["current_durability"])
		# Không đặt quantity trong metadata để giống _on_drop_pressed
		# Sử dụng hướng ngẫu nhiên để tương tự hiệu ứng phân tán
		var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var drop_distance = 30
		dropped_item.global_position = position + (direction * drop_distance)
		
		# Thêm vào node Ground
		if get_tree().root.get_node("Ground"):
			get_tree().root.get_node("Ground").add_child(dropped_item)

		
func save_chest_data_with_data(data: Dictionary):
	var file = FileAccess.open("user://chest_data.save", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  ", true))
		file.close()
