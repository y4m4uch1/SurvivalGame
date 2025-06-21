extends StaticBody2D

@export var boss_scene: PackedScene # Cảnh của boss
@export var spawn_position: Vector2 = Vector2(100, 0) # Vị trí boss xuất hiện so với totem
@export var boss_music_tracks: Array[AudioStream] = [] # Danh sách nhạc cho boss cụ thể
@onready var area_2d: Area2D = $Area2D
@onready var label: Label = $Label
var player_in_range: bool = false
var boss_spawned: bool = false
var boss_instance: Node = null # Lưu trữ tham chiếu đến boss
var previous_music: AudioStream = null # Lưu trữ nhạc đang phát trước khi boss xuất hiện

func _ready():
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("ui_interact") and not boss_spawned:
		summon_boss()

func _on_body_entered(body):
	if body.is_in_group("player"): # Giả sử nhân vật người chơi thuộc group "player"
		player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func summon_boss():
	if boss_scene:
		boss_instance = boss_scene.instantiate()
		boss_instance.global_position = global_position + spawn_position
		get_tree().current_scene.add_child(boss_instance)
		boss_spawned = true
		# Di chuyển totem đến vị trí ngẫu nhiên trong khu vực (x: 0, y: 0, w: 4800, h: 4000)
		var spawn_area_min = Vector2(0, 0) # Góc trên bên trái
		var spawn_area_max = spawn_area_min + Vector2(4800, 4000) # Góc dưới bên phải
		var new_position = Vector2(
			randf_range(spawn_area_min.x, spawn_area_max.x),
			randf_range(spawn_area_min.y, spawn_area_max.y)
		)
		global_position = new_position
		# Phát nhạc boss
		if boss_music_tracks.size() > 0:
			var main_script = get_tree().root.get_node("Ground")
			var background_music = main_script.get_node("BackgroundMusic")
			if background_music:
				# Lưu trữ nhạc hiện tại
				previous_music = background_music.stream
				# Dừng nhạc hiện tại
				if background_music.playing:
					background_music.stop()
				# Phát một bài nhạc boss ngẫu nhiên
				var random_index = randi() % boss_music_tracks.size()
				background_music.stream = boss_music_tracks[random_index]
				background_music.volume_db = -10.0
				background_music.play()
				# Thông báo cho script_main rằng đang phát nhạc boss
				if main_script.has_method("set_boss_music_playing"):
					main_script.set_boss_music_playing(true)
		# Kết nối với tín hiệu died của boss
		if boss_instance.has_signal("died"):
			boss_instance.died.connect(_on_boss_died)

func _on_boss_died():
	boss_spawned = false
	boss_instance = null # Xóa tham chiếu đến boss
	# Khôi phục nhạc trước đó
	var main_script = get_tree().root.get_node("Ground")
	var background_music = main_script.get_node("BackgroundMusic")
	if background_music and previous_music:
		if background_music.playing:
			background_music.stop()
		background_music.stream = previous_music
		background_music.volume_db = -10.0
		background_music.play()
		# Thông báo cho script_main rằng đã dừng nhạc boss
		if main_script.has_method("set_boss_music_playing"):
			main_script.set_boss_music_playing(false)
		previous_music = null
