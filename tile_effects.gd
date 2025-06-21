extends Node

# Định nghĩa các hiệu ứng ô cho từng khu vực
var tile_effects = {
	"Swamp": {
		Vector2i(4, 0): {"speed": 20}  # Ô Mud trong Swamp giảm tốc độ xuống 20
	},
	"Cave": {
		Vector2i(3, 19): {"damage": 5, "interval": 1.0}  # Ô Lava trong Cave gây 5 sát thương mỗi 1 giây
	}
}

# Lưu trữ timer cho mỗi người chơi và hiệu ứng sát thương
var damage_timers = {}

func apply_tile_effect(player: Node, tile_map: TileMap, current_world: String):
	if not player or not tile_map:
		return
	
	var player_id = player.get_instance_id()
	var player_tile_pos = tile_map.local_to_map(player.global_position)
	var tile_data = tile_map.get_cell_tile_data(0, player_tile_pos)
	
	if tile_data:
		var atlas_coords = tile_map.get_cell_atlas_coords(0, player_tile_pos)
		if current_world in tile_effects and atlas_coords in tile_effects[current_world]:
			var effect = tile_effects[current_world][atlas_coords]
			# Áp dụng hiệu ứng tốc độ
			if "speed" in effect:
				player.speed = effect["speed"]
			# Áp dụng hiệu ứng sát thương
			if "damage" in effect:
				var timer_key = str(player_id) + "_" + str(atlas_coords)
				if not timer_key in damage_timers:
					damage_timers[timer_key] = 0.0
				damage_timers[timer_key] += get_process_delta_time()
				if damage_timers[timer_key] >= effect["interval"]:
					player.take_damage(effect["damage"], true)
					player.show_notification("Burned by lava! -" + str(effect["damage"]) + " HP")
					damage_timers[timer_key] = 0.0
		else:
			player.update_stats()  # Khôi phục tốc độ ban đầu
			_clear_timer(player_id, atlas_coords)
	else:
		player.update_stats()  # Khôi phục tốc độ ban đầu
		_clear_timer(player_id, Vector2i(-1, -1)) 

func _clear_timer(player_id: int, atlas_coords: Vector2i):
	var timer_key = str(player_id) + "_" + str(atlas_coords)
	if timer_key in damage_timers:
		damage_timers[timer_key] = 0.0
