extends Node

@export_group("Ayarlar")
@export var volume_slider: Range

@export var music: AudioStreamPlayer

@export_group("Zorluk")
@export var difficulty_text: Label

var _is_muted := false
var _last_volume := 1.0


func _ready() -> void:
	Input.set_custom_mouse_cursor(null)
	if music:
		(music.stream as AudioStreamMP3).loop = true

	var saved_volume := Settings.volume
	if volume_slider:
		volume_slider.set_value_no_signal(saved_volume)
		volume_slider.value_changed.connect(set_volume)

	if saved_volume == 0.0: _is_muted = true
	else: _last_volume = saved_volume

	_update_difficulty_text()


func next_difficulty() -> void:
	_change_difficulty(1)


func previous_difficulty() -> void:
	_change_difficulty(-1)


func _change_difficulty(direction: int) -> void:
	var count := Settings.Difficulty.size()
	Settings.difficulty = ((Settings.difficulty + direction + count) % count) as Settings.Difficulty
	_update_difficulty_text()


func _update_difficulty_text() -> void:
	if difficulty_text:
		difficulty_text.text = Settings.display_name(Settings.difficulty)


func set_volume(volume: float) -> void:
	Settings.volume = volume

	if volume > 0.0:
		_is_muted = false
		_last_volume = volume
	else:
		_is_muted = true


func toggle_mute() -> void:
	if _is_muted:
		_is_muted = false
		Settings.volume = _last_volume
	else:
		_is_muted = true
		_last_volume = Settings.volume if Settings.volume > 0.0 else 1.0
		Settings.volume = 0.0

	if volume_slider: volume_slider.set_value_no_signal(Settings.volume)


func play_game() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func quit_game() -> void:
	get_tree().quit()
