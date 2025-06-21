extends CanvasLayer
signal settings_closed

# Default input map
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

# Save file path
const SAVE_PATH = "user://settings.save"

@onready var master_volume = $ColorRect/MasterVolume
@onready var music = $ColorRect/Music
@onready var footstep = $ColorRect/Footstep
@onready var scroll_container = $ColorRect/ScrollContainer
@onready var default_button = $ColorRect/Default
@onready var save_button = $ColorRect/Save
@onready var close_button = $ColorRect/Close

var input_buttons = {}
var current_input = null
var settings = {}

func _ready():
	# Connect button signals
	save_button.pressed.connect(_on_save_pressed)
	default_button.pressed.connect(_on_default_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Load saved settings
	load_settings()
	
	# Setup volume sliders
	setup_volume_sliders()
	
	# Create input mapping UI
	create_input_mapping_ui()

func setup_volume_sliders():
	# Initialize volume sliders (0 to 100)
	master_volume.max_value = 100
	music.max_value = 100
	footstep.max_value = 100
	
	# Load saved volume values or set defaults
	master_volume.value = settings.get("master_volume", 80)
	music.value = settings.get("music_volume", 80)
	footstep.value = settings.get("footstep_volume", 80)
	
	# Connect value changed signals
	master_volume.value_changed.connect(_on_master_volume_changed)
	music.value_changed.connect(_on_music_volume_changed)
	footstep.value_changed.connect(_on_footstep_volume_changed)

func create_input_mapping_ui():
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	for action in DEFAULT_INPUTS.keys():
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = action.replace("ui_", "").capitalize()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var button = Button.new()
		var keycode = settings.get(action, OS.find_keycode_from_string(DEFAULT_INPUTS[action]))
		button.text = OS.get_keycode_string(keycode)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_input_button_pressed.bind(action))
		
		input_buttons[action] = button
		hbox.add_child(label)
		hbox.add_child(button)
		vbox.add_child(hbox)
	
	scroll_container.add_child(vbox)

func _on_input_button_pressed(action):
	current_input = action
	for btn in input_buttons.values():
		btn.disabled = true
	set_process_input(true)

func _input(event):
	if current_input and event is InputEventKey and event.pressed:
		# Update input map
		var key_event = event as InputEventKey
		InputMap.action_erase_events(current_input)
		InputMap.action_add_event(current_input, key_event)
		
		# Update button text
		input_buttons[current_input].text = key_event.as_text()
		
		# Lưu keycode
		settings[current_input] = key_event.keycode
		
		# Reset state
		current_input = null
		for btn in input_buttons.values():
			btn.disabled = false
		set_process_input(false)

func _on_master_volume_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value/100.0))
	settings["master_volume"] = value

func _on_music_volume_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value/100.0))
	settings["music_volume"] = value

func _on_footstep_volume_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Footstep"), linear_to_db(value/100.0))
	settings["footstep_volume"] = value

func _on_save_pressed():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(settings)
		file.close()

func _on_default_pressed():
	# Reset volume sliders
	master_volume.value = 80
	music.value = 80
	footstep.value = 80
	
	# Reset input map
	for action in DEFAULT_INPUTS.keys():
		InputMap.action_erase_events(action)
		var event = InputEventKey.new()
		event.keycode = OS.find_keycode_from_string(DEFAULT_INPUTS[action])
		InputMap.action_add_event(action, event)
		input_buttons[action].text = DEFAULT_INPUTS[action]
		settings[action] = event.keycode
	
	# Save default settings
	_on_save_pressed()

func _on_close_pressed():
	visible = false
	emit_signal("settings_closed")

func load_settings():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			settings = file.get_var()
			file.close()
			
			# Apply saved volume settings
			if settings.has("master_volume"):
				master_volume.value = settings["master_volume"]
			if settings.has("music_volume"):
				music.value = settings["music_volume"]
			if settings.has("footstep_volume"):
				footstep.value = settings["footstep_volume"]
			
			# Apply saved input mappings
			for action in DEFAULT_INPUTS.keys():
				if settings.has(action):
					var event = InputEventKey.new()
					event.keycode = settings[action]
					InputMap.action_erase_events(action)
					InputMap.action_add_event(action, event)
					if input_buttons.has(action):
						input_buttons[action].text = OS.get_keycode_string(settings[action])
	else:
		# Initialize default settings
		settings = {
			"master_volume": 80,
			"music_volume": 80,
			"footstep_volume": 80
		}
		for action in DEFAULT_INPUTS.keys():
			settings[action] = OS.find_keycode_from_string(DEFAULT_INPUTS[action])
