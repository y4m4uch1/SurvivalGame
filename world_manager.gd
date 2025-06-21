# WorldManager.gd
extends Node

func get_current_world_and_container() -> Dictionary:
	var root = get_tree().root
	var worlds = [
		{"path": "Ground/World", "node": root.get_node_or_null("Ground/World")},
		{"path": "Ground/CaveWorld", "node": root.get_node_or_null("Ground/CaveWorld")},
		{"path": "Ground/SwampWorld", "node": root.get_node_or_null("Ground/SwampWorld")},
		{"path": "Ground/DesertWorld", "node": root.get_node_or_null("Ground/DesertWorld")}
	]
	
	var current_world = null
	var other_container = null
	
	for world_info in worlds:
		var world = world_info["node"]
		if world and world.visible:
			current_world = world
			other_container = world.get_node_or_null("OtherContainer")
			break
	
	return {"world": current_world, "container": other_container}
