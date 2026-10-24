extends Node

# Unity'deki DifficultySettings + PlayerPrefs karşılığı (autoload: Settings)

enum Difficulty { EASY, NORMAL, HARD }

# 1 Unity birimi = 64 piksel; Unity'deki tüm mesafe/hız değerleri bununla çarpılır
const UNIT := 64.0

const SAVE_PATH := "user://settings.cfg"

var difficulty: Difficulty = Difficulty.NORMAL:
	set(value):
		difficulty = value
		_save()

var volume: float = 1.0:
	set(value):
		volume = value
		AudioServer.set_bus_volume_db(0, linear_to_db(value))
		_save()


func _ready() -> void:
	_add_inputs()

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		difficulty = clampi(config.get_value("game", "difficulty", Difficulty.NORMAL), 0, 2) as Difficulty
		volume = config.get_value("game", "volume", 1.0)
	else:
		volume = 1.0


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "difficulty", difficulty)
	config.set_value("game", "volume", volume)
	config.save(SAVE_PATH)


func display_name(value: Difficulty) -> String:
	match value:
		Difficulty.EASY: return "KOLAY"
		Difficulty.HARD: return "ZOR"
		_: return "NORMAL"


# Oyun başındaki düşman hızı; zamanla speed_growth_per_minute kadar artar (max_speed_bonus'a kadar)
func enemy_speed_multiplier() -> float: return _pick(0.85, 1.05, 1.15)
func speed_growth_per_minute() -> float: return _pick(0.05, 0.1, 0.15)
func max_speed_bonus() -> float: return _pick(0.25, 0.5, 0.6)

# Spawn aralığı başlangıçtan minimuma ramp_duration saniyede iner (küçük = daha sık düşman)
func start_interval_multiplier() -> float: return _pick(1.4, 1.15, 1.0)
func min_interval_multiplier() -> float: return _pick(1.3, 1.0, 0.7)
func ramp_duration() -> float: return _pick(300.0, 180.0, 120.0)

func multi_shot_drop_chance() -> float: return _pick(0.03, 0.02, 0.01)
func magnet_drop_chance() -> float: return _pick(0.0225, 0.015, 0.0075)
func saber_drop_chance() -> float: return _pick(0.015, 0.01, 0.005)


func _pick(easy: float, normal: float, hard: float) -> float:
	match difficulty:
		Difficulty.EASY: return easy
		Difficulty.HARD: return hard
		_: return normal


# Unity'nin Horizontal/Vertical eksenleri (WASD + oklar), Fire1, Shift, Q, Esc
func _add_inputs() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("move_up", [KEY_W, KEY_UP])
	_add_keys("move_down", [KEY_S, KEY_DOWN])
	_add_keys("dash", [KEY_SHIFT])
	_add_keys("nuke", [KEY_Q])
	_add_keys("pause", [KEY_ESCAPE])

	InputMap.add_action("fire")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("fire", click)


func _add_keys(action: String, keys: Array) -> void:
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
