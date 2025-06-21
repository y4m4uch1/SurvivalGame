extends StaticBody2D

@export var max_health: int = 750
var current_health: int
var item_data = preload("res://GUI/Inventory/ItemDatabase.gd").new().get_item_data()

func _ready():
	set_meta("structure_name", "WoodenSpikes")  # Ensure meta is set
	var structure_name = get_meta("structure_name", "")
	if structure_name == "WoodenSpikes" and item_data["Structure"].has("WoodenSpikes"):
		max_health = item_data["Structure"]["WoodenSpikes"].get("health", max_health)
	current_health = max_health
	set_meta("health", current_health)
	print("WoodenSpikes initialized at position: ", global_position)

func take_damage(amount: int, attacker: Node = null):
	current_health -= amount
	set_meta("health", current_health)
	
	# Gây sát thương ngược lại cho slime nếu attacker là slime
	if attacker and attacker.is_in_group("enemy") and attacker.has_method("take_damage"):
		attacker.take_damage(10)  # Gây 10 sát thương cho slime
		print("WoodenSpikes dealt 10 damage to slime at position: ", attacker.global_position)
	
	if current_health <= 0:
		var player = get_tree().root.get_node_or_null("Ground/Player")
		if player:
			# Tìm structure trong player.placed_structures dựa trên global_position
			var target_structure_data = null
			for structure in player.placed_structures:
				var stored_pos = Vector2(
					structure["tile_position"]["x"] * 16 + 8,
					structure["tile_position"]["y"] * 16 + 8
				)
				if (structure["structure_name"] == "WoodenSpikes" and
					global_position.distance_to(stored_pos) < 16):
					target_structure_data = structure
					break
			
			if target_structure_data:
				player.placed_structures.erase(target_structure_data)
				if player.has_method("show_notification"):
					player.show_notification("WoodenSpikes destroyed!")
			
			# Xóa node khỏi game world
			queue_free()
	else:
		print("WoodenSpikes health: ", current_health)

func set_saved_health(health: int):
	current_health = health
	set_meta("health", current_health)
