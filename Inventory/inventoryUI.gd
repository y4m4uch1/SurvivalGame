extends CanvasLayer

var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
var item_data = item_db.get_item_data()

@onready var player = get_parent().get_node("Player")
@onready var grid_container = $ColorRect/ScrollContainer/GridContainer
@onready var drop_button = $ColorRect/HBoxContainer/Drop
@onready var split_button = $ColorRect/HBoxContainer/Split
@onready var use_button = $ColorRect/HBoxContainer/Use
@onready var helmet_texture_rect = $ColorRect/Helmet
@onready var armor_texture_rect = $ColorRect/Armor
@onready var weapon_texture_rect = $ColorRect/Weapon
@onready var backpack_texture_rect = $ColorRect/Backpack
@onready var shoes_texture_rect = $ColorRect/Shoes
@onready var damage_label = $ColorRect/Damage
@onready var defense_label = $ColorRect/Defense
@onready var movespeed_label = $ColorRect/MoveSpeed

var max_stack = 10  # Giới hạn stack tối đa

# InventoryUI.gd
var placed_structures = []  # Mảng lưu thông tin các structure đã đặt
var selected_slot: int = -1
var selected_equipment_slot: String = "" # Lưu slot trang bị được chọn (Helmet, Armor, v.v.)

var is_dragging: bool = false  # Trạng thái đang kéo
var dragged_item: Dictionary = {}  # Thông tin vật phẩm đang được kéo
var dragged_texture_rect: TextureRect = null  # TextureRect hiển thị vật phẩm đang kéo
var dragged_from_slot: int = -1  # Slot mà vật phẩm được kéo từ đó

# Biến để quản lý chế độ đặt structure
var is_placing_structure: bool = false
var structure_to_place: String = ""  # Tên của structure đang được đặt
var structure_sprite: Sprite2D = null  # Sprite của structure để hiển thị tại con trỏ
var structure_collision_shape: CollisionShape2D = null  # CollisionShape2D tạm thời để hiển thị va chạm

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not player:
		print("Warning: Player node not found!")
	
	drop_button.connect("pressed", Callable(self, "_on_drop_pressed"))
	split_button.connect("pressed", Callable(self, "_on_split_pressed"))
	use_button.connect("pressed", Callable(self, "_on_use_pressed"))
	helmet_texture_rect.connect("gui_input", Callable(self, "_on_equipment_slot_clicked").bind("Helmet"))
	armor_texture_rect.connect("gui_input", Callable(self, "_on_equipment_slot_clicked").bind("Armor"))
	weapon_texture_rect.connect("gui_input", Callable(self, "_on_equipment_slot_clicked").bind("Weapon"))
	backpack_texture_rect.connect("gui_input", Callable(self, "_on_equipment_slot_clicked").bind("Backpack"))
	shoes_texture_rect.connect("gui_input", Callable(self, "_on_equipment_slot_clicked").bind("Shoes"))
	
	update_equipment_textures()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_inventory"):
		visible = !visible
		if visible:
			update_inventory()
		else:
			selected_slot = -1
			selected_equipment_slot = ""
			if is_dragging:
				cancel_drag()

	# Đóng InventoryUI khi nhấn bất kỳ phím nào (trừ phím di chuyển) nếu UI đang hiển thị
	elif visible and event is InputEventKey and event.pressed and \
		 not event.is_action("ui_up") and \
		 not event.is_action("ui_down") and \
		 not event.is_action("ui_left") and \
		 not event.is_action("ui_right"):
		visible = false
		selected_slot = -1
		selected_equipment_slot = ""
		if is_dragging:
			cancel_drag()
		update_inventory()

	if is_placing_structure:
		# Xử lý nút chuột trái để đặt structure
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			place_structure()
		# Xử lý phím xoay structure
		elif event.is_action_pressed("ui_rotate"):
			rotate_structure()
		# Hủy đặt structure khi nhấn phím bất kỳ (trừ phím di chuyển) hoặc nút chuột khác
		elif (event is InputEventKey and event.pressed and 
			  not event.is_action("ui_up") and 
			  not event.is_action("ui_down") and 
			  not event.is_action("ui_left") and 
			  not event.is_action("ui_right")) or \
			 (event is InputEventMouseButton and event.pressed and event.button_index != MOUSE_BUTTON_LEFT):
			cancel_structure_placement()

	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var drop_position = get_viewport().get_mouse_position()
		var target_slot = get_slot_at_position(drop_position)
		var target_equipment_slot = get_equipment_slot_at_position(drop_position)

		# Thả trong inventory
		if target_slot != -1 and target_slot < player.max_slots:
			if dragged_from_slot != target_slot:
				# Đảm bảo inventory có đủ slot
				while player.inventory.size() <= target_slot:
					player.inventory.append({})
				
				var temp = player.inventory[target_slot].duplicate() if not player.inventory[target_slot].is_empty() else {}
				
				if temp.is_empty():
					# Slot đích trống, đặt vật phẩm kéo vào
					player.inventory[target_slot] = dragged_item.duplicate()
					player.inventory[dragged_from_slot] = {}
					selected_slot = -1
				else:
					# Slot đích đã có vật phẩm, kiểm tra gộp
					if (temp["name"] == dragged_item["name"] and 
						not temp.has("current_durability") and 
						not dragged_item.has("current_durability")):
						var total_quantity = temp["quantity"] + dragged_item["quantity"]
						if total_quantity <= max_stack:
							player.inventory[target_slot]["quantity"] = total_quantity
							player.inventory[dragged_from_slot] = {}
							selected_slot = -1
						else:
							player.inventory[target_slot]["quantity"] = max_stack
							dragged_item["quantity"] = total_quantity - max_stack
							player.inventory[dragged_from_slot] = dragged_item.duplicate()
					else:
						# Không gộp được, tìm slot trống hoặc hoán đổi
						var empty_slot = -1
						for i in range(player.inventory.size()):
							if player.inventory[i].is_empty() and i != dragged_from_slot:
								empty_slot = i
								break
						if empty_slot == -1 and player.inventory.size() < player.max_slots:
							empty_slot = player.inventory.size()
							player.inventory.append({})
						
						if empty_slot != -1:
							player.inventory[empty_slot] = temp.duplicate()
							player.inventory[target_slot] = dragged_item.duplicate()
							player.inventory[dragged_from_slot] = {}
							selected_slot = -1
						else:
							player.inventory[target_slot] = dragged_item.duplicate()
							player.inventory[dragged_from_slot] = temp.duplicate()
							selected_slot = -1

		# Thả vào equipment slot
		elif target_equipment_slot != "":
			if player.equip_item(dragged_item["name"], target_equipment_slot, dragged_item.get("current_durability", -1)):
				player.inventory[dragged_from_slot] = {}
			else:
				player.show_notification("Cannot equip item!")
				end_drag()
				return

		end_drag()
		update_inventory()

# Hàm xoay structure
func rotate_structure():
	if structure_sprite and structure_collision_shape:
		# Xoay thêm 90 độ mỗi lần nhấn R
		structure_sprite.rotation_degrees += 90
		structure_collision_shape.rotation_degrees += 90
		# Đảm bảo góc xoay nằm trong khoảng 0-360 độ
		if structure_sprite.rotation_degrees >= 360:
			structure_sprite.rotation_degrees -= 360
			structure_collision_shape.rotation_degrees -= 360

func _process(delta: float) -> void:
	# Cập nhật vị trí của structure sprite theo con trỏ chuột
	if is_placing_structure and structure_sprite:
		var mouse_pos = get_viewport().get_mouse_position()
		var world_pos = get_viewport().get_camera_2d().get_global_mouse_position()
		structure_sprite.global_position = world_pos
	
	# Cập nhật vị trí của vật phẩm đang kéo
	if is_dragging and dragged_texture_rect:
		dragged_texture_rect.position = get_viewport().get_mouse_position() - dragged_texture_rect.size / 2

func update_inventory():
	# Đảm bảo player.inventory không vượt quá max_slots
	while player.inventory.size() > player.max_slots:
		player.inventory.pop_back()
	
	for child in grid_container.get_children():
		child.queue_free()

	grid_container.columns = 3
	var slots_to_display = player.max_slots

	for i in range(slots_to_display):
		var item_container = VBoxContainer.new()
		item_container.custom_minimum_size = Vector2(100, 100)

		var texture_rect = TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(64, 64)

		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# Đảm bảo slot tồn tại trong inventory
		while player.inventory.size() <= i:
			player.inventory.append({})
		
		if not player.inventory[i].is_empty():
			var item = player.inventory[i]
			var item_name = item["name"]
			var quantity = int(item["quantity"])  # Ép kiểu quantity về int

			for category in item_data.keys():
				if item_name in item_data[category]:
					texture_rect.texture = load(item_data[category][item_name]["texture"])
					break

			if item.has("current_durability"):
				label.text = item_name + ": " + str(quantity) + "\nDurability: " + str(int(item["current_durability"]))  # Ép kiểu durability về int
			else:
				label.text = item_name + ": " + str(quantity)
		else:
			label.text = "Empty"

		item_container.connect("gui_input", Callable(self, "_on_slot_clicked").bind(i))

		if i == selected_slot or i == dragged_from_slot:
			item_container.modulate = Color(1, 1, 0, 1)
		else:
			item_container.modulate = Color(1, 1, 1, 1)

		item_container.add_child(texture_rect)
		item_container.add_child(label)
		grid_container.add_child(item_container)
	
	var scroll_container = $ColorRect/ScrollContainer
	scroll_container.custom_minimum_size = Vector2(320, 200)
	grid_container.custom_minimum_size = Vector2(320, ceil(slots_to_display / float(grid_container.columns)) * 100)
	
	update_equipment_textures()
	
	if player:
		damage_label.text = "Damage: " + str(player.attack_damage)
		defense_label.text = "Defense: " + str(player.defense)
		movespeed_label.text = "Move Speed: " + str(player.speed)
	else:
		damage_label.text = "Damage: N/A"
		defense_label.text = "Defense: N/A"
		movespeed_label.text = "Move Speed: N/A"

func update_equipment_textures():
	# Helmet
	if player.equipment["Helmet"] != null and player.equipment["Helmet"]["name"] in item_data["Helmet"]:
		helmet_texture_rect.texture = load(item_data["Helmet"][player.equipment["Helmet"]["name"]]["texture"])
		helmet_texture_rect.tooltip_text = "Durability: " + str(player.equipment["Helmet"]["current_durability"]) + "/50"
	else:
		helmet_texture_rect.texture = null
		helmet_texture_rect.tooltip_text = ""

	# Armor
	if player.equipment["Armor"] != null and player.equipment["Armor"]["name"] in item_data["Armor"]:
		armor_texture_rect.texture = load(item_data["Armor"][player.equipment["Armor"]["name"]]["texture"])
		armor_texture_rect.tooltip_text = "Durability: " + str(player.equipment["Armor"]["current_durability"]) + "/50"
	else:
		armor_texture_rect.texture = null
		armor_texture_rect.tooltip_text = ""

	# Weapon
	if player.equipment["Weapon"] != null and player.equipment["Weapon"]["name"] in item_data["Weapons"]:
		weapon_texture_rect.texture = load(item_data["Weapons"][player.equipment["Weapon"]["name"]]["texture"])
		weapon_texture_rect.tooltip_text = "Durability: " + str(player.equipment["Weapon"]["current_durability"]) + "/50"
	else:
		weapon_texture_rect.texture = null
		weapon_texture_rect.tooltip_text = ""

	# Backpack
	if player.equipment["Backpack"] != null and player.equipment["Backpack"]["name"] in item_data["Backpack"]:
		backpack_texture_rect.texture = load(item_data["Backpack"][player.equipment["Backpack"]["name"]]["texture"])
		backpack_texture_rect.tooltip_text = ""
	else:
		backpack_texture_rect.texture = null
		backpack_texture_rect.tooltip_text = ""

	# Shoes
	if player.equipment["Shoes"] != null and player.equipment["Shoes"]["name"] in item_data["Shoes"]:
		shoes_texture_rect.texture = load(item_data["Shoes"][player.equipment["Shoes"]["name"]]["texture"])
		shoes_texture_rect.tooltip_text = "Durability: " + str(player.equipment["Shoes"]["current_durability"]) + "/50"
	else:
		shoes_texture_rect.texture = null
		shoes_texture_rect.tooltip_text = ""

func _on_slot_clicked(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and slot_index < player.inventory.size() and not is_dragging:
			# Kiểm tra xem slot có trống không
			if player.inventory[slot_index].is_empty():
				return  # Nếu slot trống, không làm gì cả
			
			# Bắt đầu kéo
			is_dragging = true
			dragged_from_slot = slot_index
			dragged_item = player.inventory[slot_index].duplicate()  # Sao chép thông tin vật phẩm
			selected_slot = slot_index
			
			# Tạo TextureRect để hiển thị vật phẩm đang kéo
			dragged_texture_rect = TextureRect.new()
			dragged_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			dragged_texture_rect.custom_minimum_size = Vector2(64, 64)
			for category in item_data.keys():
				if dragged_item["name"] in item_data[category]:
					dragged_texture_rect.texture = load(item_data[category][dragged_item["name"]]["texture"])
					break
			dragged_texture_rect.modulate = Color(1, 1, 1, 0.7)  # Làm mờ nhẹ để phân biệt
			add_child(dragged_texture_rect)
			
			update_inventory()

func _on_equipment_slot_clicked(event: InputEvent, slot: String):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if player.equipment[slot] != null:
			selected_equipment_slot = slot
			selected_slot = -1 # Bỏ chọn slot inventory nếu chọn slot trang bị
			update_inventory()
		else:
			selected_equipment_slot = ""
			update_inventory()

func _on_use_pressed():
	# Xử lý tháo trang bị
	if selected_equipment_slot != "":
		if player.equipment[selected_equipment_slot] != null:
			if player.unequip_item(selected_equipment_slot):
				selected_equipment_slot = ""
				update_inventory()
			else:
				print("Cannot unequip", selected_equipment_slot, ": Inventory full!")
		else:
			selected_equipment_slot = ""
		return

	# Xử lý dùng item từ inventory
	if selected_slot == -1 or selected_slot >= player.inventory.size():
		print("No slot selected or invalid slot!")
		return

	var item = player.inventory[selected_slot]
	var item_name = item["name"]
	var quantity = item["quantity"]
	var current_durability = item.get("current_durability", -1)  # Lấy độ bền từ slot được chọn

	# Kiểm tra nếu là Structure
	if item_name in item_data["Structure"]:
		start_structure_placement(item_name)
		item["quantity"] -= 1
		if item["quantity"] <= 0:
			player.inventory.remove_at(selected_slot)
			selected_slot = -1
		update_inventory()
	
	# Kiểm tra nếu là Consumables
	elif item_name in item_data["Consumables"]:
		if item_name == "Bolas":
			# Trang bị Bolas vào slot Weapon thay vì ném ngay
			if player.equip_item(item_name, "Weapon", -1):  # Không cần durability cho Bolas
				item["quantity"] -= 1
				if item["quantity"] <= 0:
					player.inventory.remove_at(selected_slot)
					selected_slot = -1
				update_inventory()
			else:
				print("Cannot equip Bolas: Inventory full or slot occupied!")
		else:
			# Logic cũ cho các consumable khác (như Apple)
			player.restore_hunger(item_data["Consumables"][item_name]["hunger_restore"] if "hunger_restore" in item_data["Consumables"][item_name] else 0)
			player.restore_thirst(item_data["Consumables"][item_name]["thirst_restore"] if "thirst_restore" in item_data["Consumables"][item_name] else 0)
			if "health_restore" in item_data["Consumables"][item_name]:
				var health_change = item_data["Consumables"][item_name]["health_restore"]
				if health_change < 0:
					player.take_damage(-health_change)
				else:
					player.health += health_change
					player.health = clamp(player.health, 0, player.max_health)
					player.health_bar.value = player.health
					player.update_health_label()
			item["quantity"] -= 1
			if item["quantity"] <= 0:
				player.inventory.remove_at(selected_slot)
				selected_slot = -1
			update_inventory()
	
	# Logic còn lại cho Armor, Weapons, Helmet, Backpack, Shoes
	elif item_name in item_data["Armor"]:
		if player.equip_item(item_name, "Armor", current_durability):
			item["quantity"] -= 1
			if item["quantity"] <= 0:
				player.inventory.remove_at(selected_slot)
				selected_slot = -1
			update_inventory()
		else:
			print("Cannot equip", item_name, ": Inventory full or slot occupied!")
	elif item_name in item_data["Weapons"]:
		if player.equip_item(item_name, "Weapon", current_durability):
			item["quantity"] -= 1
			if item["quantity"] <= 0:
				player.inventory.remove_at(selected_slot)
				selected_slot = -1
			update_inventory()
		else:
			print("Cannot equip", item_name, ": Inventory full or slot occupied!")
	elif item_name in item_data["Helmet"]:
		if player.equip_item(item_name, "Helmet", current_durability):
			item["quantity"] -= 1
			if item["quantity"] <= 0:
				player.inventory.remove_at(selected_slot)
				selected_slot = -1
			update_inventory()
		else:
			print("Cannot equip", item_name, ": Inventory full or slot occupied!")
	elif item_name in item_data["Backpack"]:
		if player.equip_item(item_name, "Backpack", current_durability):
			item["quantity"] -= 1
			if item["quantity"] <= 0:
				player.inventory.remove_at(selected_slot)
				selected_slot = -1
			update_inventory()
		else:
			print("Cannot equip", item_name, ": Inventory full or slot occupied!")
	elif item_name in item_data["Shoes"]:
		if player.equip_item(item_name, "Shoes", current_durability):
			item["quantity"] -= 1
			if item["quantity"] <= 0:
				player.inventory.remove_at(selected_slot)
				selected_slot = -1
			update_inventory()
		else:
			print("Cannot equip", item_name, ": Inventory full or slot occupied!")
	else:
		print("Cannot use item:", item_name)

func start_structure_placement(structure_name: String):
	is_placing_structure = true
	structure_to_place = structure_name
	
	# Ẩn InventoryUI
	self.visible = false
	
	# Ẩn CraftUI nếu tồn tại
	var craft_ui = get_parent().get_node_or_null("CraftUI")
	if craft_ui:
		craft_ui.visible = false
	
	# Tạo Sprite2D cho structure
	structure_sprite = Sprite2D.new()
	var structure_data = item_data["Structure"][structure_name]
	structure_sprite.texture = load(structure_data["texture"])
	structure_sprite.scale = structure_data["scale"]
	structure_sprite.rotation_degrees = 0
	get_tree().root.get_node("Ground").add_child(structure_sprite)
	
	# Tạo CollisionShape2D tạm thời để hiển thị và xoay
	var shape = null
	if structure_data.has("scene_path"):
		# Tải scene để lấy thông tin collision
		var scene = load(structure_data["scene_path"])
		var scene_instance = scene.instantiate()
		var collision_node = find_collision_shape(scene_instance)
		
		if collision_node and collision_node.shape:
			shape = collision_node.shape.duplicate()
			# Nếu scene có CollisionShape2D, sử dụng nó
			structure_collision_shape = CollisionShape2D.new()
			structure_collision_shape.shape = shape
			structure_collision_shape.rotation_degrees = 0
			structure_sprite.add_child(structure_collision_shape)
		else:
			# Nếu scene không có CollisionShape2D, sử dụng Area2D với shape từ item_data
			var area = Area2D.new()
			structure_collision_shape = CollisionShape2D.new()
			var collision_shape_data = structure_data["collision_shape"]
			if collision_shape_data["type"] == "Rectangle":
				shape = RectangleShape2D.new()
				shape.extents = collision_shape_data["size"] / 2
			elif collision_shape_data["type"] == "Circle":
				shape = CircleShape2D.new()
				shape.radius = collision_shape_data["radius"]
			structure_collision_shape.shape = shape
			area.add_child(structure_collision_shape)
			structure_sprite.add_child(area)
		
		# Giải phóng scene instance
		scene_instance.queue_free()
	else:
		# Không có scene_path, sử dụng collision_shape từ item_data
		var collision_shape_data = structure_data["collision_shape"]
		if collision_shape_data["type"] == "Rectangle":
			shape = RectangleShape2D.new()
			shape.extents = collision_shape_data["size"] / 2
		elif collision_shape_data["type"] == "Circle":
			shape = CircleShape2D.new()
			shape.radius = collision_shape_data["radius"]
		
		structure_collision_shape = CollisionShape2D.new()
		structure_collision_shape.shape = shape
		structure_collision_shape.rotation_degrees = 0
		structure_sprite.add_child(structure_collision_shape)
	
	# Thông báo đặc biệt cho Hammer
	if structure_name == "Hammer":
		player.show_notification("Hammer can only be placed on a structure!")
# InventoryUI.gd
func place_structure():
	if not is_placing_structure:
		return

	if structure_to_place == "Hammer":
		# Giữ nguyên logic cho Hammer
		var placement_position = structure_sprite.global_position
		var space_state = player.get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = placement_position
		query.collide_with_bodies = true
		query.collision_mask = 1

		var results = space_state.intersect_point(query)
		var target_structure = null
		var target_structure_data = null

		for result in results:
			var collider = result["collider"]
			if collider is StaticBody2D and collider.has_meta("structure_name"):
				var structure_name = collider.get_meta("structure_name")
				if structure_name in item_data["Structure"]:
					target_structure = collider
					for i in range(player.placed_structures.size()):
						var structure = player.placed_structures[i]
						var structure_pos = Vector2(
							structure["tile_position"]["x"] * 16 + 8,
							structure["tile_position"]["y"] * 16 + 8
						)
						if structure["structure_name"] == structure_name and \
						   target_structure.global_position.distance_to(structure_pos) < 16:
							target_structure_data = structure
							break
					break

		if target_structure and target_structure_data:
			target_structure.queue_free()
			player.placed_structures.erase(target_structure_data)
			player.show_notification("Structure removed with Hammer!")
			is_placing_structure = false
			structure_to_place = ""
			structure_sprite.queue_free()
			structure_sprite = null
			structure_collision_shape = null
		else:
			player.show_notification("No structure found to remove with Hammer!")
			return
		return

	if structure_to_place == "BaseMarker":
		var base_marker_count = 0
		for structure in player.placed_structures:
			if structure["structure_name"] == "BaseMarker":
				base_marker_count += 1
		if base_marker_count >= 2:
			player.show_notification("Cannot place more than 2 Base Markers!")
			cancel_structure_placement()
			return

	var placement_position = structure_sprite.global_position

	if is_colliding_at_position(placement_position):
		player.show_notification("Cannot place structure: Collision detected!")
		return

	var structure_data = item_data["Structure"][structure_to_place]
	var structure_instance = null

	if structure_data.has("scene_path"):
		var scene = load(structure_data["scene_path"])
		structure_instance = scene.instantiate()
		structure_instance.global_position = placement_position
		structure_instance.rotation_degrees = structure_sprite.rotation_degrees
	else:
		structure_instance = StaticBody2D.new()
		structure_instance.collision_layer = 1
		structure_instance.collision_mask = 1

		var sprite = Sprite2D.new()
		sprite.texture = load(structure_data["texture"])
		sprite.scale = structure_data["scale"]
		sprite.rotation_degrees = structure_sprite.rotation_degrees
		sprite.z_index = 0
		structure_instance.add_child(sprite)

		var collision_shape = CollisionShape2D.new()
		var collision_shape_data = structure_data["collision_shape"]
		var shape = null
		if collision_shape_data["type"] == "Rectangle":
			shape = RectangleShape2D.new()
			shape.extents = collision_shape_data["size"] / 2
		elif collision_shape_data["type"] == "Circle":
			shape = CircleShape2D.new()
			shape.radius = collision_shape_data["radius"]
		collision_shape.shape = shape
		collision_shape.rotation_degrees = structure_sprite.rotation_degrees
		structure_instance.add_child(collision_shape)

		structure_instance.set_meta("structure_name", structure_to_place)
		structure_instance.set_meta("scale", structure_data["scale"])
		structure_instance.set_meta("collision_type", collision_shape_data["type"])
		structure_instance.set_meta("collision_data", collision_shape_data)
		structure_instance.set_meta("rotation_degrees", structure_sprite.rotation_degrees)

		structure_instance.global_position = placement_position

	# Sử dụng WorldManager để lấy thế giới và container
	var world_manager = get_node("/root/WorldManager")  # Đảm bảo WorldManager là singleton
	var world_info = world_manager.get_current_world_and_container()
	var current_world = world_info["world"]
	var other_container = world_info["container"]

	# Thêm structure vào thế giới tương ứng
	if other_container:
		other_container.add_child(structure_instance)
	elif current_world:
		current_world.add_child(structure_instance)
	else:
		player.show_notification("Cannot place structure: No valid world found!")
		structure_instance.queue_free()
		is_placing_structure = false
		structure_to_place = ""
		structure_sprite.queue_free()
		structure_sprite = null
		structure_collision_shape = null
		return

	if current_world and player:
		var collision_data = item_data["Structure"][structure_to_place]["collision_shape"]
		player.add_placed_structure(
			structure_to_place,
			structure_instance.global_position,
			structure_data["scale"],
			collision_data["type"],
			collision_data,
			structure_sprite.rotation_degrees
		)
		player.show_notification("Placed " + structure_to_place + " successfully!")

	is_placing_structure = false
	structure_to_place = ""
	structure_sprite.queue_free()
	structure_sprite = null
	structure_collision_shape = null

# Hàm kiểm tra va chạm tại vị trí định đặt
func is_colliding_at_position(position: Vector2) -> bool:
	var space_state = player.get_world_2d().direct_space_state
	var structure_data = item_data["Structure"][structure_to_place]
	var shape = null
	var transform = Transform2D(structure_sprite.rotation, position)
	
	if structure_data.has("scene_path"):
		var scene = load(structure_data["scene_path"])
		var scene_instance = scene.instantiate()
		var collision_node = find_collision_shape(scene_instance)
		
		if collision_node and collision_node.shape:
			shape = collision_node.shape.duplicate()
			var query = PhysicsShapeQueryParameters2D.new()
			query.shape = shape
			query.transform = transform
			query.collide_with_bodies = true
			query.collide_with_areas = true
			query.collision_mask = 1   # Kiểm tra cả layer 1 và 2
			var results = space_state.intersect_shape(query)
			scene_instance.queue_free()
			return results.size() > 0
		else:
			# Sử dụng Area2D để kiểm tra
			var area = Area2D.new()
			area.collision_layer = 1
			area.collision_mask = 1 
			var temp_collision_shape = CollisionShape2D.new()
			var collision_shape_data = structure_data["collision_shape"]
			if collision_shape_data["type"] == "Rectangle":
				shape = RectangleShape2D.new()
				shape.extents = collision_shape_data["size"] / 2
			elif collision_shape_data["type"] == "Circle":
				shape = CircleShape2D.new()
				shape.radius = collision_shape_data["radius"]
			temp_collision_shape.shape = shape
			area.add_child(temp_collision_shape)
			area.global_position = position
			area.rotation = structure_sprite.rotation

			get_tree().root.add_child(area)
			var overlapping = area.get_overlapping_bodies().size() > 0 or area.get_overlapping_areas().size() > 0
			area.queue_free()
			return overlapping
	else:
		var collision_shape_data = structure_data["collision_shape"]
		if collision_shape_data["type"] == "Rectangle":
			shape = RectangleShape2D.new()
			shape.extents = collision_shape_data["size"] / 2
		elif collision_shape_data["type"] == "Circle":
			shape = CircleShape2D.new()
			shape.radius = collision_shape_data["radius"]
		
		var query = PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = transform
		query.collide_with_bodies = true
		query.collide_with_areas = true
		query.collision_mask = 1 | 2
		
		var results = space_state.intersect_shape(query)
		return results.size() > 0
		
# Hàm tìm CollisionShape2D trong scene
func find_collision_shape(node: Node) -> CollisionShape2D:
	for child in node.get_children():
		if child is CollisionShape2D and child.shape:
			return child
		var found = find_collision_shape(child)
		if found:
			return found
	return null

func cancel_structure_placement():
	# Hủy chế độ đặt structure
	if is_placing_structure:
		# Lưu tên structure trước khi xóa
		var structure_name = structure_to_place
		is_placing_structure = false
		structure_to_place = ""
		if structure_sprite:
			structure_sprite.queue_free()
			structure_sprite = null
		if structure_collision_shape:
			structure_collision_shape = null
		# Thêm lại structure vào inventory nếu tên hợp lệ
		if structure_name != "":
			player.add_to_inventory(structure_name)
		else:
			print("Error: No structure name to add back to inventory!")

func _on_drop_pressed():
	if selected_slot == -1 or selected_slot >= player.inventory.size():
		player.show_notification("No slot selected or invalid slot!")
		return

	var item = player.inventory[selected_slot]
	var item_name = item["name"]
	var quantity = item["quantity"]
	var current_durability = item.get("current_durability", -1)

	var item_scene = preload("res://GUI/Inventory/Item.tscn")
	
	var direction = Vector2.ZERO
	var sprite = player.get_node("Head")
	match sprite.frame:
		0: direction = Vector2.DOWN
		1: direction = Vector2.LEFT
		2: direction = Vector2.RIGHT
		3: direction = Vector2.UP
	
	var drop_distance = 30
	
	# Sử dụng WorldManager để lấy thế giới và container
	var world_manager = get_node("/root/WorldManager")
	var world_info = world_manager.get_current_world_and_container()
	var current_world = world_info["world"]
	var other_container = world_info["container"]

	# Thả từng item
	for i in range(quantity):
		var dropped_item = item_scene.instantiate()
		dropped_item.item_name = item_name
		dropped_item.position = player.global_position + (direction * drop_distance)
		if current_durability >= 0:
			dropped_item.set_meta("current_durability", current_durability)
		
		if other_container:
			other_container.add_child(dropped_item)
		elif current_world:
			current_world.add_child(dropped_item)
		else:
			player.show_notification("Cannot drop item: No valid world found!")
			dropped_item.queue_free()
			continue

		if current_world:
			print("Dropped item:", item_name, "in", current_world.name, "at position:", dropped_item.position)

	player.inventory.remove_at(selected_slot)
	selected_slot = -1
	update_inventory()

func _on_split_pressed():
	if selected_slot == -1 or selected_slot >= player.inventory.size():
		return
	
	var item = player.inventory[selected_slot]
	var item_name = item["name"]
	var quantity = item["quantity"]
	var current_durability = item.get("current_durability", -1)  # Lấy độ bền nếu có

	if quantity <= 1:
		return

	# Tìm slot trống trong inventory
	var empty_slot = -1
	for i in range(player.inventory.size()):
		if player.inventory[i].is_empty():
			empty_slot = i
			break
	
	if empty_slot == -1 and player.inventory.size() < player.max_slots:
		# Nếu không có slot trống nhưng inventory chưa đầy, thêm một slot mới
		empty_slot = player.inventory.size()
		player.inventory.append({})
	
	if empty_slot == -1:
		return

	# Chia stack thành hai phần, đảm bảo số nguyên
	var drop_quantity = int(quantity / 2)  # Số lượng chuyển sang slot mới (làm tròn xuống)
	var keep_quantity = quantity - drop_quantity  # Số lượng giữ lại ở slot cũ (bao gồm phần dư)

	# Tạo item mới cho slot trống
	var new_item = {"name": item_name, "quantity": drop_quantity}
	if current_durability >= 0:
		new_item["current_durability"] = current_durability  # Giữ nguyên độ bền nếu có

	# Cập nhật slot cũ
	item["quantity"] = keep_quantity

	# Đặt item mới vào slot trống
	player.inventory[empty_slot] = new_item

	# Bỏ chọn slot và cập nhật UI
	selected_slot = -1
	update_inventory()

# Hàm để tìm slot tại vị trí chuột
func get_slot_at_position(position: Vector2) -> int:
	for i in range(grid_container.get_child_count()):
		var slot = grid_container.get_child(i)
		var rect = slot.get_global_rect()
		if rect.has_point(position):
			return i
	return -1

# Hàm để tìm equipment slot tại vị trí chuột
func get_equipment_slot_at_position(position: Vector2) -> String:
	if helmet_texture_rect.get_global_rect().has_point(position):
		return "Helmet"
	if armor_texture_rect.get_global_rect().has_point(position):
		return "Armor"
	if weapon_texture_rect.get_global_rect().has_point(position):
		return "Weapon"
	if backpack_texture_rect.get_global_rect().has_point(position):
		return "Backpack"
	if shoes_texture_rect.get_global_rect().has_point(position):
		return "Shoes"
	return ""

func end_drag():
	is_dragging = false
	dragged_item = {}
	dragged_from_slot = -1
	if dragged_texture_rect:
		dragged_texture_rect.queue_free()
		dragged_texture_rect = null

func cancel_drag():
	if dragged_from_slot != -1 and not dragged_item.is_empty():
		# Đặt lại vật phẩm vào slot ban đầu nếu hủy
		player.inventory[dragged_from_slot] = dragged_item.duplicate()
	end_drag()
