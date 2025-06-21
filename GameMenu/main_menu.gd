extends CanvasLayer

var is_rotating = false  # Flag to control rotation
var rotation_speed = 2.0  # Speed of rotation in radians per second
var scene_to_load: String  # Path of the scene to load
var is_loading = false  # Flag to track if loading is in progress
@onready var loading = $Control/Loading
@onready var background_music = $BackgroundMusic
@onready var message_label = $Label

# Danh sách các file nhạc cho menu
var menu_music_tracks = [
	preload("res://GUI/GameMenu/MenuMusic1.wav"),  
	preload("res://GUI/GameMenu/MenuMusic2.wav"),  
	preload("res://GUI/GameMenu/MenuMusic3.wav"),  
]
var setting_ui_instance = null
func _ready():
	$ColorRect/VBoxContainer/NewGame.pressed.connect(_on_new_game_pressed)
	$ColorRect/VBoxContainer/Load.pressed.connect(_on_load_pressed)
	$ColorRect/VBoxContainer/Setting.pressed.connect(_on_setting_pressed)
	$ColorRect/VBoxContainer/Quit.pressed.connect(_on_quit_pressed)
	# Initially hide the Loading TextureRect
	loading.hide()
	loading.modulate = Color(1, 1, 1, 1)  # Ensure opacity is full
	
	# Kết nối tín hiệu "finished" để phát nhạc mới khi bài hiện tại kết thúc
	if background_music:
		background_music.connect("finished", Callable(self, "_on_music_finished"))
		# Phát bài nhạc ngẫu nhiên khi bắt đầu
		play_random_music()
	else:
		print("Error: BackgroundMusic not found")

func _process(delta):
	if is_rotating:
		loading.rotation += rotation_speed * delta  # Rotate the Loading TextureRect
	
	# Handle asynchronous loading
	if is_loading and scene_to_load != "":
		var status = ResourceLoader.load_threaded_get_status(scene_to_load)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			# Scene is fully loaded, instance it and switch
			var resource = ResourceLoader.load_threaded_get(scene_to_load)
			var scene = resource.instantiate()
			get_tree().root.add_child(scene)
			get_tree().current_scene = scene
			# Stop rotation and hide loading UI
			is_rotating = false
			is_loading = false
			loading.hide()
			# Re-enable buttons
			for button in $ColorRect/VBoxContainer.get_children():
				if button is Button:
					button.disabled = false
			queue_free()
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			is_rotating = false
			is_loading = false
			loading.hide()
			# Re-enable buttons
			for button in $ColorRect/VBoxContainer.get_children():
				if button is Button:
					button.disabled = false
			scene_to_load = ""

func _on_new_game_pressed():
	Global.is_loading_game = false
	start_loading("res://Main/main.tscn")

func _on_load_pressed():
	# Check if a save file exists
	if not FileAccess.file_exists("user://savegame.save"):
		message_label.text = "No save file found! Please start a new game."
		message_label.show()
		# Start a timer to hide the label after 3 seconds
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func(): message_label.hide())
		return
	
	Global.is_loading_game = true
	start_loading("res://Main/main.tscn")

func start_loading(scene_path: String):
	is_rotating = true  # Start rotating
	is_loading = true  # Mark loading as in progress
	loading.show()  # Show the Loading TextureRect
	print("Loading TextureRect shown, visibility: ", loading.visible)
	
	# Disable all buttons in VBoxContainer
	for button in $ColorRect/VBoxContainer.get_children():
		if button is Button:
			button.disabled = true
	
	# Start asynchronous loading
	scene_to_load = scene_path
	var err = ResourceLoader.load_threaded_request(scene_path)
	if err != OK:
		print("Error starting threaded load: ", err)
		is_rotating = false
		is_loading = false
		loading.hide()
		# Re-enable buttons
		for button in $ColorRect/VBoxContainer.get_children():
			if button is Button:
				button.disabled = false
		scene_to_load = ""

func _on_setting_pressed():
	if not setting_ui_instance:
		var setting_ui_scene = preload("res://GUI/Setting/SettingUI.tscn")
		setting_ui_instance = setting_ui_scene.instantiate()
		setting_ui_instance.connect("settings_closed", Callable(self, "_on_settings_closed"))
		add_child(setting_ui_instance)
	setting_ui_instance.visible = true
	# Disable main menu buttons while settings UI is open
	for button in $ColorRect/VBoxContainer.get_children():
		if button is Button:
			button.disabled = true

func _on_settings_closed():
	for button in $ColorRect/VBoxContainer.get_children():
		if button is Button:
			button.disabled = false
	if setting_ui_instance:
		setting_ui_instance.queue_free()
		setting_ui_instance = null


func _on_quit_pressed():
	get_tree().quit()

# Hàm chọn và phát một bài nhạc ngẫu nhiên
func play_random_music():
	if not background_music:
		return
	
	if menu_music_tracks.size() > 0:
		var random_index = randi() % menu_music_tracks.size()
		background_music.stream = menu_music_tracks[random_index]
		background_music.volume_db = -10.0  # Điều chỉnh âm lượng nếu cần
		background_music.play()

# Hàm được gọi khi nhạc kết thúc
func _on_music_finished():
	play_random_music()
