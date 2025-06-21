extends Node

var is_loading_game: bool = false

const SAVE_PATH = "user://settings.save"
const DEFAULT_INPUTS = {
	"ui_left": "A",
	"ui_right": "D",
	"ui_up": "W",
	"ui_down": "S",
	"ui_interact": "E",
	"ui_inventory": "I",
	"ui_map": "M",
	"ui_craft": "B"
}

var settings = {}

func _ready():
	load_settings()
	apply_audio_settings()

func load_settings():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			settings = file.get_var()
			file.close()
			
			# Apply saved input mappings
			for action in DEFAULT_INPUTS.keys():
				if settings.has(action):
					var event = InputEventKey.new()
					event.keycode = settings[action]
					InputMap.action_erase_events(action)
					InputMap.action_add_event(action, event)
	else:
		# Initialize default settings
		settings = {
			"master_volume": 80,
			"music_volume": 80,
			"footstep_volume": 80
		}
		for action in DEFAULT_INPUTS.keys():
			settings[action] = OS.find_keycode_from_string(DEFAULT_INPUTS[action])
			var event = InputEventKey.new()
			event.keycode = settings[action]
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, event)

func apply_audio_settings():
	if settings.has("master_volume"):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(settings["master_volume"]/100.0))
	if settings.has("music_volume"):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(settings["music_volume"]/100.0))
	if settings.has("footstep_volume"):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Footstep"), linear_to_db(settings["footstep_volume"]/100.0))

func save_settings():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(settings)
		file.close()
