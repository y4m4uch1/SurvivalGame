extends Node2D

const DAY_DURATION = 380
const NIGHT_DURATION = 140
const RAIN_CHECK_INTERVAL = 1200
const RAIN_DURATION_MIN = 180
const RAIN_DURATION_MAX = 300
const RAIN_CHANCE = 0.5

const DAY_COLOR = Color(1, 1, 1, 1)
const NIGHT_COLOR = Color(0.2, 0.2, 0.4, 1)
const RAIN_COLOR = Color(0.1, 0.1, 0.3, 1)

@onready var canvas_modulate = $CanvasModulate
@onready var day_night_timer = $DayNightTimer
@onready var rain_timer = $RainTimer
@onready var day_label = get_node("/root/Ground/CanvasLayer/Day")
@onready var rain_particles = $CPUParticles2D
@onready var player = get_node("/root/Ground/Player")
@onready var rain_sound = $RainSound

var is_day = true
var current_day = 1
var transition_progress = 0.0
var transition_speed = 0.0
var is_raining = false
var current_color = DAY_COLOR
var color_transition_speed = 2.0

func _ready():
	day_night_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	rain_timer.connect("timeout", Callable(self, "_on_rain_timer_timeout"))
	rain_sound.connect("finished", Callable(self, "_on_rain_sound_finished"))
	
	day_night_timer.wait_time = DAY_DURATION
	day_night_timer.start()
	rain_timer.wait_time = RAIN_CHECK_INTERVAL
	rain_timer.start()
	
	transition_speed = 1.0 / DAY_DURATION
	if is_day:
		transition_progress = 1.0
		canvas_modulate.color = DAY_COLOR
		current_color = DAY_COLOR
	else:
		transition_progress = 1.0
		canvas_modulate.color = NIGHT_COLOR
		current_color = NIGHT_COLOR
	
	rain_particles.emitting = false
	rain_sound.stop()
	update_day_label()

func _process(delta):
	var target_color
	if is_raining:
		target_color = RAIN_COLOR
	else:
		target_color = DAY_COLOR if is_day else NIGHT_COLOR
	
	current_color = current_color.lerp(target_color, color_transition_speed * delta)
	canvas_modulate.color = current_color
	
	if is_raining and player:
		rain_particles.global_position = player.global_position
		rain_sound.global_position = player.global_position

func _on_timer_timeout():
	is_day = !is_day
	transition_progress = 0.0
	
	if is_day:
		day_night_timer.wait_time = DAY_DURATION
		transition_speed = 1.0 / DAY_DURATION
		current_day += 1
		update_day_label()
	else:
		day_night_timer.wait_time = NIGHT_DURATION
		transition_speed = 1.0 / NIGHT_DURATION
	
	day_night_timer.start()

func _on_rain_timer_timeout():
	var random_value = randf()
	if not is_raining and random_value < RAIN_CHANCE:
		start_rain()
	elif is_raining:
		stop_rain()
	else:
		rain_timer.wait_time = RAIN_CHECK_INTERVAL
		rain_timer.start()

func start_rain():
	is_raining = true
	var rain_duration = randf_range(RAIN_DURATION_MIN, RAIN_DURATION_MAX)
	rain_timer.wait_time = rain_duration
	rain_timer.start()
	rain_particles.emitting = true
	rain_sound.play()
	update_day_label()

func stop_rain():
	is_raining = false
	rain_timer.wait_time = RAIN_CHECK_INTERVAL
	rain_timer.start()
	rain_particles.emitting = false
	rain_sound.stop()
	update_day_label()

func _on_rain_sound_finished():
	if is_raining:
		rain_sound.play()

func update_day_label():
	day_label.text = "Day " + str(current_day) + (" (Raining)" if is_raining else "")

# Thêm phương thức để lấy trạng thái hiện tại
func get_day_night_state():
	return {
		"is_day": is_day,
		"current_day": current_day,
		"day_night_timer_remaining": day_night_timer.time_left,
		"is_raining": is_raining,
		"rain_timer_remaining": rain_timer.time_left
	}

func set_day_night_state(state):
	is_day = state["is_day"]
	current_day = state["current_day"]
	day_night_timer.wait_time = DAY_DURATION if is_day else NIGHT_DURATION
	day_night_timer.start(state["day_night_timer_remaining"])
	
	is_raining = state["is_raining"]
	if is_raining:
		rain_timer.wait_time = state["rain_timer_remaining"]
		rain_timer.start()
		rain_particles.emitting = true
		rain_sound.play()
	else:
		# Sử dụng rain_timer_remaining từ file lưu thay vì RAIN_CHECK_INTERVAL
		rain_timer.wait_time = state["rain_timer_remaining"]
		rain_timer.start()
		rain_particles.emitting = false
		rain_sound.stop()
	
	update_day_label()

func get_current_day() -> int:
	return current_day
