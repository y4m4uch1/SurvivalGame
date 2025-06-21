extends CharacterBody2D

signal player_died()
# Chỉ số mặc định
var base_speed = 20
var base_defense = 0
var base_attack_damage = 1

var attack_cooldown = 0.7  # Thời gian chờ 0.5 giây
var last_attack_time = 0.0  # Thời điểm lần tấn công cuối cùng

# Chỉ số hiện tại
var speed = base_speed
var defense = base_defense
var attack_damage = base_attack_damage

var max_health = 100
var health = max_health
var max_hunger = 100
var hunger = max_hunger
var max_thirst = 100
var thirst = max_thirst

var inventory = []
var max_slots = 9
var max_stack = 10

var equipment = {
	"Helmet": null,
	"Armor": null,
	"Backpack": null,
	"Shoes": null,
	"Weapon": null
}
@onready var tile_map = get_node("../World")
var swamp_world: Node2D = null  # Thay vì @onready, khởi tạo null
var cave_world: Node2D = null   # Thay vì @onready, khởi tạo null
@onready var day_night_cycle = get_node("/root/Ground/World/DayNightWeather") 
var item_db = preload("res://GUI/Inventory/ItemDatabase.gd").new()
var item_data = item_db.get_item_data()

@onready var footstep_sound = $AudioStreamPlayer2D
@onready var attack_sound = $AttackSound
var footstep_timer = 0.0
var footstep_interval = 0.5
@onready var texture_rect = $TextureRect
@onready var head_sprite = $Head
@onready var body_sprite = $Body
@onready var health_bar = get_node("/root/Ground/CanvasLayer/HealthBar")
@onready var health_label = get_node("/root/Ground/CanvasLayer/HealthLabel")
@onready var hunger_bar = get_node("/root/Ground/CanvasLayer/HungerBar")
@onready var hunger_label = get_node("/root/Ground/CanvasLayer/HungerLabel")
@onready var thirst_bar = get_node("/root/Ground/CanvasLayer/ThirstBar")
@onready var thirst_label = get_node("/root/Ground/CanvasLayer/ThirstLabel")
@onready var inventory_ui = get_node("/root/Ground/InventoryUI")
@onready var crafting_ui = get_node("../CraftingUI")
@onready var notification_label = get_node("../CanvasLayer/NotificationLabel")
@onready var full_map = get_node("/root/Ground/Map")  # Tham chiếu đến Map
@onready var WeaponNode = get_node("Weapon")  # Node2D
@onready var Weapon = get_node("Weapon/Weapon")  # Sprite2D
@onready var WeaponNode2 = get_node("Weapon2")  # Node2D
@onready var Weapon2 = get_node("Weapon2/Weapon")  # Sprite2D
@onready var chest_ui = get_node("/root/Ground/ChestUI")
@onready var attack_hitbox = get_node("Weapon/AttackHitbox")
# Player.gd
var placed_structures = []  # Mảng lưu thông tin các structure đã đặt
var near_structure: String = ""  # Lưu tên structure thay vì boolean
var near_chest_node: StaticBody2D = null
var default_texture = preload("res://Player/Sprites/player.png")
var default_scale = Vector2(0.03, 0.03)

var time_since_last_decrease = 0.0
var decrease_interval = 10.0
var damage_timer = 0.0

var attack_range_line: Polygon2D
var is_attacking = false  # Biến theo dõi trạng thái tấn công

# Từ điển lưu trữ thông số position và rotation cho Weapon2 theo loại vũ khí và hướng
var weapon_positions = {
	"Sword": {
		0: {"position": Vector2(2, 3), "rotation": 0.628319, "offset": Vector2(0, -500)},  # Xuống
		1: {"position": Vector2(-2, 3), "rotation": -0.628319, "offset": Vector2(0, -500)}, # Trái
		2: {"position": Vector2(2, 3), "rotation": 0.628319, "offset": Vector2(0, -500)},  # Phải
		3: {"position": Vector2(8, -5), "rotation": 0.628319, "offset": Vector2(0, -100)}  # Lên
	},
	"Spear": {
		0: {"position": Vector2(2, 3), "rotation": 0.628319, "offset": Vector2(0, -500)},  # Xuống
		1: {"position": Vector2(-2, 3), "rotation": -0.628319, "offset": Vector2(0, -500)}, # Trái
		2: {"position": Vector2(2, 3), "rotation": 0.628319, "offset": Vector2(0, -500)},  # Phải
		3: {"position": Vector2(8, -5), "rotation": 0.628319, "offset": Vector2(0, -100)}  # Lên
	},
	# Thêm các vũ khí khác tại đây, ví dụ:
	"Axe": {
		0: {"position": Vector2(2, 3), "rotation": 0.628319, "offset": Vector2(0, -500)},
		1: {"position": Vector2(-2, 3), "rotation": -0.628319, "offset": Vector2(0, -500)},
		2: {"position": Vector2(2, 3), "rotation": 0.628319, "offset": Vector2(0, -500)},
		3: {"position": Vector2(8, -5), "rotation": 0.628319, "offset": Vector2(0, -100)}
	},
	"PickAxe": {
		0: {"position": Vector2(2, 3), "rotation": 0.628319, "offset": Vector2(0, -500)},
		1: {"position": Vector2(-2, 3), "rotation": -0.628319, "offset": Vector2(0, -500)},
		2: {"position": Vector2(2, 3), "rotation": 0.628319, "offset": Vector2(0, -500)},
		3: {"position": Vector2(8, -5), "rotation": 0.628319, "offset": Vector2(0, -100)}
	},
	"GreatSword": {
		0: {"position": Vector2(-9, 5), "rotation": 0, "offset": Vector2(0, -700)},
		1: {"position": Vector2(0, 4), "rotation": 0.261799, "offset": Vector2(0, -700)},
		2: {"position": Vector2(0, 4), "rotation": -0.261799, "offset": Vector2(0, -700)},
		3: {"position": Vector2(9, -10), "rotation": 0, "offset": Vector2(0, -100)}
	}
}

func _ready():
	Weapon.texture = null
	
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.modulate = Color(1, 0, 0)
	update_health_label()

	hunger_bar.max_value = max_hunger
	hunger_bar.value = hunger
	hunger_bar.modulate = Color(1, 0.5, 0)
	update_hunger_label()

	thirst_bar.max_value = max_thirst
	thirst_bar.value = thirst
	thirst_bar.modulate = Color(0, 0, 1)
	update_thirst_label()

	if has_node("Area2D"):
		$Area2D.connect("area_entered", Callable(self, "_on_area_entered"))

	attack_range_line = Polygon2D.new()
	attack_range_line.color = Color(1, 0, 0, 0.5)  # Màu đỏ với độ trong suốt 0.5
	attack_range_line.visible = false
	add_child(attack_range_line)
	
		# Khởi tạo hitbox tấn công
	attack_hitbox = Area2D.new()
	attack_hitbox.name = "AttackHitbox"
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "HitboxCollisionShape"
	attack_hitbox.add_child(collision_shape)
	attack_hitbox.collision_layer = 0
	attack_hitbox.collision_mask = collision_mask  # Sử dụng cùng collision_mask như raycast
	attack_hitbox.monitoring = false  # Tắt theo dõi mặc định
	add_child(attack_hitbox)
	attack_hitbox.connect("body_entered", Callable(self, "_on_hitbox_body_entered"))
	attack_hitbox.connect("area_entered", Callable(self, "_on_hitbox_area_entered"))
	update_stats()
	update_visuals()  # Cập nhật giao diện sau khi tháo trang bị
	
func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if not is_attacking:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	if swamp_world and swamp_world.visible:
		TileEffects.apply_tile_effect(self, swamp_world, "Swamp")
	elif cave_world and cave_world.visible:
		TileEffects.apply_tile_effect(self, cave_world, "Cave")
	else:
		update_stats()
		TileEffects._clear_timer(get_instance_id(), Vector2i(-1, -1))
	
	if not is_attacking:
		Weapon.visible = false  # Hide Weapon1 when not attacking
		if equipment["Weapon"] != null:
			Weapon2.visible = true  # Show Weapon2 when not attacking
		else:
			Weapon2.visible = false  # Hide Weapon2 if no weapon
	else:
		Weapon.visible = true   # Show Weapon1 when attacking
		Weapon2.visible = false # Hide Weapon2 when attacking
	
	# Update Weapon (Weapon1) direction based on mouse and Weapon2 based on movement
	if equipment["Weapon"] != null:
		# Weapon (Weapon1) follows mouse
		var mouse_position = get_global_mouse_position()
		var mouse_direction = (mouse_position - global_position).normalized()
		var angle = atan2(mouse_direction.y, mouse_direction.x)

		# Rotate WeaponNode (Weapon1) to follow mouse
		if not is_attacking:
			WeaponNode.rotation = angle
			WeaponNode.position = Vector2(mouse_direction.x * 4, mouse_direction.y * 4)  # Slight offset for positioning

		# Get the weapon type from ItemDatabase
		var weapon_name = equipment["Weapon"]["name"]
		var weapon_type = "Sword"  # Default to Sword
		for category in item_data.keys():
			if weapon_name in item_data[category] and "tool_type" in item_data[category][weapon_name]:
				weapon_type = item_data[category][weapon_name]["tool_type"]
				break

		# Update sprite and Weapon2 based on movement direction
		if velocity != Vector2.ZERO:
			var facing_direction = body_sprite.frame  # 0: Down, 1: Left, 2: Right, 3: Up
			if abs(velocity.x) > abs(velocity.y):
				if velocity.x > 0:
					body_sprite.frame = 2  # Right
					head_sprite.frame = body_sprite.frame
					facing_direction = 2
				else:
					body_sprite.frame = 1  # Left
					head_sprite.frame = body_sprite.frame
					facing_direction = 1
			else:
				if velocity.y > 0:
					body_sprite.frame = 0  # Down
					head_sprite.frame = body_sprite.frame
					facing_direction = 0
				else:
					body_sprite.frame = 3  # Up
					head_sprite.frame = body_sprite.frame
					facing_direction = 3

			# Apply weapon_positions for Weapon2 if the weapon_type exists
			if weapon_type in weapon_positions and facing_direction in weapon_positions[weapon_type]:
				var config = weapon_positions[weapon_type][facing_direction]
				Weapon2.position = config["position"]
				Weapon2.rotation = config["rotation"]
				Weapon2.offset = config["offset"]
	else:
		# No weapon equipped, update sprite based on movement
		if velocity != Vector2.ZERO:
			if abs(velocity.x) > abs(velocity.y):
				if velocity.x > 0:
					body_sprite.frame = 2  # Right
					head_sprite.frame = body_sprite.frame
				else:
					body_sprite.frame = 1  # Left
					head_sprite.frame = body_sprite.frame
			else:
				if velocity.y > 0:
					body_sprite.frame = 0  # Down
					head_sprite.frame = body_sprite.frame
				else:
					body_sprite.frame = 3  # Up
					head_sprite.frame = body_sprite.frame
		Weapon2.texture = null  # Hide Weapon2 if no weapon

	if velocity != Vector2.ZERO:
		footstep_timer += delta
		if footstep_timer >= footstep_interval:
			if not footstep_sound.playing:
				footstep_sound.play()
			footstep_timer = 0.0
	else:
		footstep_timer = footstep_interval
		
	time_since_last_decrease += delta
	if time_since_last_decrease >= decrease_interval:
		reduce_hunger(1)
		reduce_thirst(1)
		time_since_last_decrease = 0.0

	damage_timer += delta
	if damage_timer >= 1.0:
		if hunger == 0 and thirst > 0:
			take_damage(1, true)
		elif thirst == 0 and hunger > 0:
			take_damage(1, true)
		elif hunger == 0 and thirst == 0:
			take_damage(2, true)
		damage_timer = 0.0

	health = clamp(health, 0, max_health)
	health_bar.value = health
	update_health_label()

	hunger = clamp(hunger, 0, max_hunger)
	hunger_bar.value = hunger
	update_hunger_label()

	thirst = clamp(thirst, 0, max_thirst)
	thirst_bar.value = thirst
	update_thirst_label()

func _on_area_entered(area: Area2D) -> void:
	var item = area.get_parent()
	if item.is_in_group("pickup"):
		var item_name = item.item_name
		var durability = item.get_meta("current_durability", -1)  # Lấy độ bền từ metadata
		if add_to_inventory(item_name, durability):
			item.queue_free()
			show_notification("Picked up " + item_name + "!")
			if inventory_ui and inventory_ui.visible:
				inventory_ui.update_inventory()

func update_health_label():
	health_label.text = "Health: " + str(health)

func update_hunger_label():
	hunger_label.text = "Hunger: " + str(hunger)

func update_thirst_label():
	thirst_label.text = "Thirst: " + str(thirst)

func reduce_hunger(amount):
	hunger -= amount
	hunger = clamp(hunger, 0, max_hunger)
	hunger_bar.value = hunger
	update_hunger_label()

func reduce_thirst(amount):
	thirst -= amount
	thirst = clamp(thirst, 0, max_thirst)
	thirst_bar.value = thirst
	update_thirst_label()

func restore_hunger(amount):
	hunger += amount
	hunger = clamp(hunger, 0, max_hunger)
	hunger_bar.value = hunger
	update_hunger_label()

func restore_thirst(amount):
	thirst += amount
	thirst = clamp(thirst, 0, max_thirst)
	thirst_bar.value = thirst
	update_thirst_label()

func take_damage(amount, ignore_defense: bool = false):
	var reduced_damage = amount if ignore_defense else max(0, amount - defense)
	health -= reduced_damage
	health = clamp(health, 0, max_health)
	health_bar.value = health
	update_health_label()
	
	if health <= 0:
		# Xóa file lưu game
		var dir = DirAccess.open("user://")
		if dir.file_exists("savegame.save"):
			dir.remove("savegame.save")
		if dir.file_exists("tilemap_data.save"):
			dir.remove("tilemap_data.save")
		if dir.file_exists("chest_data.save"):
			dir.remove("chest_data.save")
		emit_signal("player_died")
		return
	
	if not ignore_defense:  # Chỉ giảm độ bền trang bị nếu không bỏ qua defense
		for slot in ["Armor", "Helmet", "Shoes"]:
			if equipment[slot] != null:
				equipment[slot]["current_durability"] -= 1
				if equipment[slot]["current_durability"] <= 0:
					show_notification(equipment[slot]["name"] + " has broken!")
					unequip_item(slot)

func attack(target):
	if not target or not target.has_method("take_damage"):
		return
	
	var weapon = equipment["Weapon"]
	var weapon_data = null
	
	# Lấy dữ liệu vũ khí nếu có
	if weapon and "name" in weapon:
		for category in item_data.keys():
			if weapon["name"] in item_data[category]:
				weapon_data = item_data[category][weapon["name"]]
				break
	
	# Kiểm tra yêu cầu công cụ nếu mục tiêu có yêu cầu
	if target.has_method("get_required_tool") and target.has_method("get_required_tier"):
		if not weapon_data or not ("tool_type" in weapon_data and "tier" in weapon_data):
			show_notification("You need a " + target.get_required_tool() + " to interact with this!")
			return
		
		var required_tool = target.get_required_tool()
		var required_tier = target.get_required_tier()
		
		if weapon_data["tool_type"] != required_tool or weapon_data["tier"] < required_tier:
			show_notification("You need a " + required_tool + " (tier " + str(required_tier) + " or higher)!")
			return
	
	# Áp dụng sát thương
	if weapon:
		target.take_damage(attack_damage)
		weapon["current_durability"] -= 1
		if weapon["current_durability"] <= 0:
			show_notification("Your " + weapon["name"] + " has broken!")
			unequip_item("Weapon")
	else:
		target.take_damage(base_attack_damage)  # Sát thương tay không nếu không có vũ khí

func show_notification(message: String, duration: float = 2.0):
	if notification_label:
		notification_label.text = message
		var timer = Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "_clear_notification"))
		add_child(timer)
		timer.start()

func _clear_notification():
	if notification_label:
		notification_label.text = ""
"""
func show_attack_range(direction: Vector2):
	var attack_info = get_weapon_attack_info()
	var range = attack_info["range"]
	var shape = attack_info["shape"]

	# Tạo vùng tấn công
	var points = []
	if shape == "cone":
		# Tạo hình nón
		var cone_angle = deg_to_rad(45)  # Góc nón 45 độ (có thể điều chỉnh)
		var num_points = 16  # Số điểm để tạo đường cong
		points.append(Vector2.ZERO)  # Điểm gốc (vị trí người chơi)
		for i in range(num_points + 1):
			var angle = -cone_angle / 2 + (cone_angle * i / num_points)
			var point = direction.rotated(angle) * range
			points.append(point)
	else:
		# Giữ nguyên đường thẳng cho các vũ khí khác
		var dir_perp = direction.rotated(deg_to_rad(90)).normalized() * 2  # Độ rộng của "đường thẳng"
		points.append(Vector2.ZERO + dir_perp)
		points.append(Vector2.ZERO - dir_perp)
		points.append(direction * range - dir_perp)
		points.append(direction * range + dir_perp)

	attack_range_line.polygon = points
	attack_range_line.visible = true

	# Tạo hiệu ứng hiển thị tạm thời
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_hide_attack_range"))
	timer.connect("timeout", Callable(self, "_on_attack_cooldown_finished"))
	timer.connect("timeout", Callable(timer, "queue_free"))
	add_child(timer)
	timer.start()

func _hide_attack_range():
	attack_range_line.visible = false
"""
func _input(event):
	if event.is_action_pressed("ui_attack"):
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_attack_time >= attack_cooldown:
			is_attacking = true  # Đặt trạng thái tấn công
			velocity = Vector2.ZERO
			if attack_sound and not attack_sound.playing:
				attack_sound.play()
			
			var weapon = equipment["Weapon"]
			var mouse_position = get_global_mouse_position()
			var direction = (mouse_position - global_position).normalized()
			var angle = atan2(direction.y, direction.x)
			var attack_info = get_weapon_attack_info()
			var range = attack_info["range"]
			var shape = attack_info["shape"]
			
			#show_attack_range(direction)
			setup_hitbox(range, shape, direction)
			attack_hitbox.monitoring = true
			
			WeaponNode.rotation = angle
			var original_position = WeaponNode.position
			var original_rotation = WeaponNode.rotation
			var original_z_index = WeaponNode.z_index

			# Pass an empty Dictionary if weapon is null
			handle_attack_animation(weapon if weapon != null else {}, direction, angle, range, shape, original_position, original_rotation, original_z_index)

			last_attack_time = current_time
	
	if event.is_action_pressed("ui_interact"):
		update_structure_detection()
		check_and_collect_water()
		toggle_chest()
	if event.is_action_pressed("ui_map"):
		toggle_map()

func toggle_map():
	if full_map:
		full_map.visible = !full_map.visible
		if full_map.visible:
			full_map.update_playable_zone()  # Cập nhật khu vực chơi khi hiển thị
		
func check_and_collect_water():
	if not tile_map:
		show_notification("Error: TileMap not found!")
		return

	var player_tile_pos = tile_map.local_to_map(global_position)
	for x in range(-1, 2):
		for y in range(-1, 2):
			var check_pos = player_tile_pos + Vector2i(x, y)
			# Kiểm tra xem check_pos có nằm trong phạm vi tilemap không
			if check_pos.x < 0 or check_pos.x >= 300 or check_pos.y < 0 or check_pos.y >= 250:
				continue
			
			var tile_data = tile_map.get_cell_tile_data(0, check_pos)
			if tile_data:
				var atlas_coords = tile_map.get_cell_atlas_coords(0, check_pos)
				if atlas_coords == Vector2i(8, 8):  # Tile nước
					if add_to_inventory("DirtyWater"):
						show_notification("Collected Dirty Water!")
					else:
						show_notification("Inventory full!")
					return

func add_to_inventory(item_name: String, durability: float = -1) -> bool:
	var final_durability = durability
	if final_durability < 0:
		var item_node = get_node_or_null("../Item")
		if item_node and item_node.has_meta("current_durability"):
			final_durability = item_node.get_meta("current_durability")
	
	# Đếm số slot thực sự chứa vật phẩm
	var filled_slots = 0
	for slot in inventory:
		if not slot.is_empty():
			filled_slots += 1
	
	var is_durable_item = false
	var found_category = ""
	for category in ["Weapons", "Armor", "Helmet", "Shoes", "Backpack"]:
		if item_name in item_data[category]:
			is_durable_item = true
			found_category = category
			break
	
	if is_durable_item:
		if filled_slots < max_slots:
			var new_slot = {"name": item_name, "quantity": 1}
			if final_durability >= 0:
				new_slot["current_durability"] = final_durability
			else:
				if "durability" in item_data[found_category][item_name]:
					new_slot["current_durability"] = item_data[found_category][item_name]["durability"]
			# Tìm slot rỗng hiện có hoặc thêm mới
			var added = false
			for i in range(inventory.size()):
				if inventory[i].is_empty():
					inventory[i] = new_slot
					added = true
					break
			if not added:
				inventory.append(new_slot)
			if inventory_ui and inventory_ui.visible:
				inventory_ui.update_inventory()
			return true
		return false
	
	# Kiểm tra gộp item
	for slot in inventory:
		if not slot.is_empty() and slot["name"] == item_name and slot["quantity"] < max_stack and not slot.has("current_durability"):
			slot["quantity"] += 1
			if inventory_ui and inventory_ui.visible:
				inventory_ui.update_inventory()
			return true
	
	# Nếu không gộp được, thêm vào slot mới
	if filled_slots < max_slots:
		var new_slot = {"name": item_name, "quantity": 1}
		var added = false
		for i in range(inventory.size()):
			if inventory[i].is_empty():
				inventory[i] = new_slot
				added = true
				break
		if not added:
			inventory.append(new_slot)
		if inventory_ui and inventory_ui.visible:
			inventory_ui.update_inventory()
		return true
	
	return false

func equip_item(item_name: String, slot: String, durability: float = -1) -> bool:
	if slot in equipment:
		if equipment[slot] != null:
			if not add_to_inventory(equipment[slot]["name"], equipment[slot]["current_durability"]):
				return false
		
		var found_category = ""
		for category in item_data.keys():
			if item_name in item_data[category]:
				found_category = category
				break
		
		var final_durability = durability if durability >= 0 else (item_data[found_category][item_name]["durability"] if "durability" in item_data[found_category][item_name] else -1)
		if durability < 0:
			if found_category and item_name in item_data[found_category] and "durability" in item_data[found_category][item_name]:
				final_durability = item_data[found_category][item_name]["durability"]
			else:
				final_durability = -1
				
		equipment[slot] = {
			"name": item_name,
			"quantity": 1,
			"current_durability": final_durability
		}
		
		update_stats()
		update_visuals()
		
		match slot:
			"Armor":
				if item_name in item_data["Armor"] and "body_texture" in item_data["Armor"][item_name]:
					body_sprite.visible = true
					body_sprite.texture = load(item_data["Armor"][item_name]["body_texture"])
			"Helmet":
				if item_name in item_data["Helmet"] and "head_texture" in item_data["Helmet"][item_name]:
					head_sprite.visible = true
					head_sprite.texture = load(item_data["Helmet"][item_name]["head_texture"])
			"Weapon":
				# Hiển thị texture cho cả Weapons và Consumables (như Bolas)
				if item_name in item_data["Weapons"]:
					Weapon.texture = load(item_data["Weapons"][item_name]["texture"])
				elif item_name in item_data["Consumables"]:
					Weapon.texture = load(item_data["Consumables"][item_name]["texture"])
				else:
					Weapon.texture = null
		
		if inventory_ui and inventory_ui.visible:
			inventory_ui.update_inventory()
		return true
	return false

func unequip_item(slot: String) -> bool:
	if slot in equipment and equipment[slot] != null:
		var item_durability = equipment[slot]["current_durability"]
		var item_name = equipment[slot]["name"]
		
		# Special handling for Backpack to prevent slot reduction issues
		if slot == "Backpack":
			var current_slots_used = inventory.size()
			var new_max_slots = 9  # Base max_slots without backpack
			if current_slots_used > new_max_slots:
				show_notification("Cannot unequip Backpack: Inventory has too many items!")
				return false
		
		# Try to add the item to inventory
		var was_added = false
		if item_durability > 0 or item_durability == -1:  # Include items without durability (like Backpack)
			was_added = add_to_inventory(item_name, item_durability)
			if not was_added:
				show_notification("Cannot unequip " + item_name + ": Inventory full!")
				return false
		
		# Clear the slot
		equipment[slot] = null
		update_stats()
		update_visuals()  # Update visuals to reset sprite to default
		if inventory_ui and inventory_ui.visible:
			inventory_ui.update_inventory()
		return true
	return false

func update_stats():
	speed = base_speed
	defense = base_defense
	attack_damage = base_attack_damage
	max_slots = 9

	# Kiểm tra Helmet
	if equipment.has("Helmet") and equipment["Helmet"] != null and equipment["Helmet"] is Dictionary and "name" in equipment["Helmet"] and equipment["Helmet"]["name"] in item_data["Helmet"]:
		defense += item_data["Helmet"][equipment["Helmet"]["name"]]["defense"]

	# Kiểm tra Armor
	if equipment.has("Armor") and equipment["Armor"] != null and equipment["Armor"] is Dictionary and "name" in equipment["Armor"] and equipment["Armor"]["name"] in item_data["Armor"]:
		defense += item_data["Armor"][equipment["Armor"]["name"]]["defense"]
		if "speed_bonus" in item_data["Armor"][equipment["Armor"]["name"]]:
			speed += item_data["Armor"][equipment["Armor"]["name"]]["speed_bonus"]

	# Kiểm tra Backpack
	if equipment.has("Backpack") and equipment["Backpack"] != null and equipment["Backpack"] is Dictionary and "name" in equipment["Backpack"] and equipment["Backpack"]["name"] in item_data["Backpack"]:
		max_slots += item_data["Backpack"][equipment["Backpack"]["name"]]["max_slots_bonus"]

	# Kiểm tra Shoes
	if equipment.has("Shoes") and equipment["Shoes"] != null and equipment["Shoes"] is Dictionary and "name" in equipment["Shoes"] and equipment["Shoes"]["name"] in item_data["Shoes"]:
		speed += item_data["Shoes"][equipment["Shoes"]["name"]]["speed_bonus"]
		if "defense" in item_data["Shoes"][equipment["Shoes"]["name"]]:
			defense += item_data["Shoes"][equipment["Shoes"]["name"]]["defense"]

	# Kiểm tra Weapon
	if equipment.has("Weapon") and equipment["Weapon"] != null and equipment["Weapon"] is Dictionary and "name" in equipment["Weapon"] and equipment["Weapon"]["name"] in item_data["Weapons"]:
		attack_damage += item_data["Weapons"][equipment["Weapon"]["name"]]["attack_damage"]

func update_visuals():
	# Default textures from player.tscn
	var default_body_texture = preload("res://Player/Sprites/Body.png")
	var default_head_texture = preload("res://Player/Sprites/Head.png")
	var fist_texture = preload("res://Player/Sprites/Fist.png") 
	# Cập nhật Armor
	if equipment["Armor"] != null and equipment["Armor"] is Dictionary and "name" in equipment["Armor"] and equipment["Armor"]["name"] in item_data["Armor"] and "body_texture" in item_data["Armor"][equipment["Armor"]["name"]]:
		body_sprite.texture = load(item_data["Armor"][equipment["Armor"]["name"]]["body_texture"])
	else:
		body_sprite.texture = default_body_texture  # Reset to default body texture

	# Cập nhật Helmet
	if equipment["Helmet"] != null and equipment["Helmet"] is Dictionary and "name" in equipment["Helmet"] and equipment["Helmet"]["name"] in item_data["Helmet"] and "head_texture" in item_data["Helmet"][equipment["Helmet"]["name"]]:
		head_sprite.texture = load(item_data["Helmet"][equipment["Helmet"]["name"]]["head_texture"])
	else:
		head_sprite.texture = default_head_texture  # Reset to default head texture
	
	# Cập nhật Weapon
	if equipment["Weapon"] != null and equipment["Weapon"] is Dictionary and "name" in equipment["Weapon"]:
		if equipment["Weapon"]["name"] in item_data["Weapons"]:
			Weapon.texture = load(item_data["Weapons"][equipment["Weapon"]["name"]]["texture"])
			Weapon2.texture = load(item_data["Weapons"][equipment["Weapon"]["name"]]["texture"])
		elif equipment["Weapon"]["name"] in item_data["Consumables"]:  # Handle Bolas
			Weapon.texture = load(item_data["Consumables"][equipment["Weapon"]["name"]]["texture"])
			Weapon2.texture = load(item_data["Consumables"][equipment["Weapon"]["name"]]["texture"])
	else:
		Weapon.texture = fist_texture
		Weapon2.texture = fist_texture

		
func update_structure_detection() -> void:
	var space_state = get_world_2d().direct_space_state
	var raycast_distance = 16.0  # Adjust as needed (e.g., one tile length)
	var direction: Vector2

	# Determine direction based on sprite frame (facing direction)
	match body_sprite.frame:
		0:  # Down
			direction = Vector2(0, 1)
		1:  # Left
			direction = Vector2(-1, 0)
		2:  # Right
			direction = Vector2(1, 0)
		3:  # Up
			direction = Vector2(0, -1)
		_:
			direction = Vector2(0, 1)  # Default to down if frame is invalid

	# Create raycast query
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction * raycast_distance,
		1  # Collision mask for structures (layer 1)
	)
	query.exclude = [self]  # Exclude the player from the raycast

	var result = space_state.intersect_ray(query)
	near_structure = ""
	near_chest_node = null

	if result and result.collider is StaticBody2D:
		var collider = result.collider
		if collider.has_meta("structure_name"):
			var structure_name = collider.get_meta("structure_name")
			if structure_name in ["CraftingTable", "Campfire", "WoodenChest", "IronChest", "Smelter", "TanningRack"]:
				near_structure = structure_name
				if structure_name in ["WoodenChest", "IronChest"]:
					near_chest_node = collider

							
func is_near_structure() -> String:  # Trả về loại structure
	return near_structure

func add_placed_structure(structure_name: String, position: Vector2, scale: Vector2, collision_type: String, collision_data: Dictionary, rotation_degrees: float = 0):
	# Chuyển đổi vị trí thế giới thành tọa độ tile
	var tile_pos = Vector2(
		position.x / 16.0,  # Giả sử TILE_SIZE = 16.0
		position.y / 16.0
	)
	var structure_data = {
		"structure_name": structure_name,
		"tile_position": {"x": tile_pos.x, "y": tile_pos.y},
		"metadata": {
			"scale": {"x": scale.x, "y": scale.y},
			"collision_type": collision_type,
			"collision_data": collision_data,
			"rotation_degrees": rotation_degrees
		}
	}
	if structure_name == "CarrotFarm":
		if day_night_cycle:
			structure_data["metadata"]["planting_day"] = day_night_cycle.get_current_day()
	# Thêm health cho các cấu trúc có type là "wall"
	if "Structure" in item_data and structure_name in item_data["Structure"]:
		if item_data["Structure"][structure_name].get("type", "") == "wall" and "health" in item_data["Structure"][structure_name]:
			structure_data["metadata"]["health"] = item_data["Structure"][structure_name]["health"]
			
	placed_structures.append(structure_data)

func get_weapon_attack_info() -> Dictionary:
	var weapon = equipment["Weapon"]
	if weapon and "name" in weapon:
		if weapon["name"] in item_data["Weapons"]:
			var weapon_data = item_data["Weapons"][weapon["name"]]
			if weapon_data.get("tool_type") == "Spear":
				return {
					"range": 50.0,  # Tầm đánh của spear
					"shape": "line",
					"hitbox_length": 50.0  # Độ dài hitbox đường thẳng
				}
			elif weapon_data.get("tool_type") in ["Sword"]:
				return {
					"range": 30.0,
					"shape": "cone",
					"hitbox_length": 30.0  # Hitbox ngắn hơn cho kiếm
				}
			elif weapon_data.get("tool_type") == "Axe":
				return {
					"range": 30.0,
					"shape": "cone",
					"hitbox_length": 30.0  # Hitbox trung bình cho rìu
				}
			elif weapon_data.get("tool_type") == "Pickaxe":
				return {
					"range": 30.0,
					"shape": "cone",
					"hitbox_length": 30.0  # Hitbox ngắn cho cuốc
				}
			elif weapon_data.get("tool_type") == "GreatSword":
				return {
					"range": 40.0,
					"shape": "cone",
					"hitbox_length": 40.0  # Hitbox dài hơn cho GreatSword
				}
			return {
				"range": weapon_data.get("attack_range", 20.0),
				"shape": "line",
				"hitbox_length": 20.0
			}
		elif weapon["name"] == "Bolas":
			return {
				"range": item_data["Consumables"]["Bolas"]["range"],
				"shape": "line",
				"hitbox_length": 20.0
			}
	# Mặc định khi không có vũ khí
	return {
		"range": 20.0,
		"shape": "line",
		"hitbox_length": 20.0
	}

func toggle_chest():
	if chest_ui:
		if near_structure in ["WoodenChest", "IronChest"]:
			chest_ui.visible = !chest_ui.visible
			if chest_ui.visible:
				if near_chest_node:  # Kiểm tra xem có chest gần đó không
					chest_ui.initialize_chest(near_structure)
				else:
					chest_ui.visible = false  # Đóng UI nếu không tìm thấy chest

func throw_bolas():
	var item_info = item_data["Consumables"]["Bolas"]
	var range = item_info.get("range", 75.0)
	
	# Tính hướng từ vị trí người chơi đến con chuột
	var mouse_position = get_global_mouse_position()
	var direction = (mouse_position - global_position).normalized()
	
	#show_attack_range(direction)
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction * range,
		collision_mask
	)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		var target = result.collider
		if target.has_method("immobilize"):
			if item_info.has("effect") and item_info["effect"] == "immobilize":
				target.immobilize(item_info["duration"])
				show_notification("Bolas immobilized " + target.name + "!")
	
	# Sau khi ném, tháo Bolas khỏi slot Weapon
	unequip_item("Weapon")

func _on_attack_cooldown_finished():
	is_attacking = false  # Cho phép di chuyển lại

func setup_hitbox(range: float, shape: String, direction: Vector2):
	var collision_shape = attack_hitbox.get_node("HitboxCollisionShape")
	
	# Xoay AttackHitbox theo hướng chuột
	var angle = atan2(direction.y, direction.x)
	attack_hitbox.rotation = angle
	
	var attack_info = get_weapon_attack_info()
	var hitbox_length = attack_info["hitbox_length"]
	
	# Tạo hitbox dạng đường thẳng cho cả line và cone
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.size = Vector2(hitbox_length, 4)  # Chiều dài = hitbox_length, chiều rộng = 4
	collision_shape.shape = rectangle_shape
	collision_shape.position = Vector2(hitbox_length / 2, 0)  # Đặt giữa hình chữ nhật

func _on_hitbox_body_entered(body: Node):
	if body == self:  # Kiểm tra nếu body là chính Player
		return  # Bỏ qua xử lý
	if is_attacking:
		# Kiểm tra Line of Sight
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			body.global_position,
			collision_mask
		)
		var result = space_state.intersect_ray(query)
		
		# Nếu raycast va chạm với một vật thể khác không phải body, bỏ qua sát thương
		if result and result.collider != body:
			return  # Có chướng ngại vật, không áp dụng sát thương
		
		# Kiểm tra xem body có CollisionShape2D không
		var has_collision_shape = false
		for child in body.get_children():
			if child is CollisionShape2D:
				has_collision_shape = true
				break
		
		if has_collision_shape:
			var weapon = equipment["Weapon"]
			if weapon and "name" in weapon and weapon["name"] == "Bolas":
				if body.has_method("immobilize"):
					var item_info = item_data["Consumables"]["Bolas"]
					if item_info.has("effect") and item_info["effect"] == "immobilize":
						body.immobilize(item_info["duration"])
						show_notification("Bolas immobilized " + body.name + "!")
					unequip_item("Weapon")
			elif body.has_method("take_damage"):
				attack(body)

func update_sprite_direction(angle: float):
	# Chuyển đổi góc sang độ để dễ xử lý
	var degrees = rad_to_deg(angle)
	
	# Xác định hướng dựa trên góc
	if degrees >= -45 and degrees < 45:
		head_sprite.frame = 2  # Phải
		body_sprite.frame = 2  # Phải
	elif degrees >= 45 and degrees < 135:
		head_sprite.frame = 0  # Xuống
		body_sprite.frame = 0
	elif degrees >= -135 and degrees < -45:
		head_sprite.frame = 3  
		body_sprite.frame = 3
	else:
		head_sprite.frame = 1 
		body_sprite.frame = 1

func handle_attack_animation(weapon: Dictionary, direction: Vector2, angle: float, range: float, shape: String, original_position: Vector2, original_rotation: float, original_z_index: int):
	if weapon and "name" in weapon:
		var is_spear = false
		var is_cone = shape == "cone"
		var is_greatsword = false
		if weapon["name"] in item_data["Weapons"]:
			var weapon_data = item_data["Weapons"][weapon["name"]]
			is_spear = weapon_data.get("tool_type") == "Spear"
			is_greatsword = weapon_data.get("tool_type") == "GreatSword"
		
		if is_spear:
			# Thrusting animation for spears
			var thrust_distance = range * 0.25
			var thrust_duration = 0.15
			var return_duration = 0.15
			
			var target_position = original_position + direction * thrust_distance
			
			var tween = create_tween()
			tween.tween_property(WeaponNode, "position", target_position, thrust_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.tween_property(WeaponNode, "position", original_position, return_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			tween.tween_callback(func():
				WeaponNode.position = original_position
				WeaponNode.rotation = original_rotation
				WeaponNode.z_index = original_z_index
				is_attacking = false
				attack_hitbox.monitoring = false
			)
		elif is_cone:
			# Cone swing animation for swords, axes, pickaxes, and GreatSword
			var swing_duration = 0.3 if not is_greatsword else 0.7
			var cone_angle = deg_to_rad(45) if not is_greatsword else deg_to_rad(180)
			var start_angle = original_rotation - cone_angle / 2
			var end_angle = original_rotation + cone_angle / 2
			
			WeaponNode.rotation = start_angle
			attack_hitbox.rotation = start_angle  # Đồng bộ hitbox với WeaponNode
			
			var tween = create_tween()
			tween.tween_property(WeaponNode, "rotation", end_angle, swing_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(attack_hitbox, "rotation", end_angle, swing_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.tween_callback(func():
				WeaponNode.position = original_position
				WeaponNode.rotation = original_rotation
				attack_hitbox.rotation = original_rotation
				WeaponNode.z_index = original_z_index
				is_attacking = false
				attack_hitbox.monitoring = false
			)
		elif weapon["name"] != "Bolas":
			# Swing animation for other weapons
			var move_distance = 0.0
			var swing_duration = 0.15
			var return_duration = 0.15
			
			var target_y = original_position.y + move_distance * sign(direction.y)
			var mid_y = original_position.y + (move_distance / 2.0) * sign(direction.y)
			
			var tween = create_tween()
			tween.tween_property(WeaponNode, "position:y", mid_y, swing_duration / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(WeaponNode, "rotation", original_rotation + deg_to_rad(60.0 * sign(direction.x)), swing_duration / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.tween_property(WeaponNode, "position:y", target_y, swing_duration / 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property(WeaponNode, "rotation", original_rotation, swing_duration / 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			tween.tween_property(WeaponNode, "position:y", original_position.y, return_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			tween.tween_callback(func():
				WeaponNode.position = original_position
				WeaponNode.rotation = original_rotation
				WeaponNode.z_index = original_z_index
				is_attacking = false
				attack_hitbox.monitoring = false
			)
		else:
			# Bolas attack
			var timer = Timer.new()
			timer.wait_time = 0.3
			timer.one_shot = true
			timer.connect("timeout", Callable(self, "_on_bolas_attack_finished"))
			add_child(timer)
			timer.start()
	else:
		# No weapon attack
		var thrust_distance = range * 0.5
		var thrust_duration = 0.15
		var return_duration = 0.15
		
		var target_position = original_position + direction * thrust_distance
		
		var tween = create_tween()
		tween.tween_property(WeaponNode, "position", target_position, thrust_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(WeaponNode, "position", original_position, return_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func():
			WeaponNode.position = original_position
			WeaponNode.rotation = original_rotation
			WeaponNode.z_index = original_z_index
			is_attacking = false
			attack_hitbox.monitoring = false
		)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if not is_attacking:
		return
	
	# Get the parent of the Area2D (the VineTree node or enemy)
	var target = area.get_parent()
	if target == self:  # Ignore if the area belongs to the player
		return
	
	# Kiểm tra xem target có CollisionShape2D không
	var has_collision_shape = false
	for child in target.get_children():
		if child is CollisionShape2D:
			has_collision_shape = true
			break
	
	# Chỉ xử lý nếu target không có CollisionShape2D
	if not has_collision_shape:
		# Check Line of Sight
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			area.global_position,
			collision_mask
		)
		var result = space_state.intersect_ray(query)
		
		# Nếu raycast va chạm với một vật thể khác không phải target, bỏ qua
		if result and result.collider != target:
			return
		
		# Handle Bolas effect
		var weapon = equipment["Weapon"]
		if weapon and "name" in weapon and weapon["name"] == "Bolas":
			if target.has_method("immobilize"):
				var item_info = item_data["Consumables"]["Bolas"]
				if item_info.has("effect") and item_info["effect"] == "immobilize":
					target.immobilize(item_info["duration"])
					show_notification("Bolas immobilized " + target.name + "!")
				unequip_item("Weapon")
		# Handle damage
		elif target.has_method("take_damage"):
			attack(target)

func update_world_references(swamp: Node2D, cave: Node2D, desert: Node2D):
	swamp_world = swamp
	cave_world = cave
