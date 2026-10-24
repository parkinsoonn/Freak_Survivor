extends Node

# Pause altında da çalışır (process_mode = Always): ESC ve panel butonları için

@export_group("UI Panelleri")
@export var game_over_panel: Control
@export var pause_panel: Control
@export var level_up_panel: Control

@export_group("Skor Sistemi")
@export var score := 0
@export var score_text: Label

@export_group("ESC Menüsü")
@export var volume_slider: Range

@export_group("Ses Ayarları")
@export var game_over_sound: AudioStream
@export var music: AudioStreamPlayer

@export_group("XP ve Seviye Sistemi")
@export var current_xp := 0
@export var current_level := 1
@export var xp_to_next_level := 5 # İlk seviye için 5 XP yetsin
@export var level_text: Label # Ekranda LEVEL: 1 yazması için

@export_group("Seviye Atlama Sesleri")
@export var level_up_sound: AudioStream

@export_group("Düşman Ölümü ve Drop'lar")
@export var death_effect: PackedScene
@export var enemy_death_sound: AudioStream
@export var xp_crystal_scene: PackedScene
@export var multi_shot_pickup_scene: PackedScene
@export var magnet_pickup_scene: PackedScene
@export var saber_pickup_scene: PackedScene

@export_group("İmleç")
@export var crosshair_cursor: Texture2D

# Unity'deki Time.timeSinceLevelLoad: pause/level-up sırasında durur
var game_time := 0.0

# Oyun durumunu kontrol eden kilitler
var _is_paused := false
var _is_game_over := false
var _is_leveling_up := false

var _player: Node
var _player_health: Node
var _camera: Node
var _saber_orbit: Node


func _enter_tree() -> void:
	add_to_group("game_manager")


func _ready() -> void:
	get_tree().paused = false
	_update_score_text()
	# Hotspot nişangahın ortası
	if crosshair_cursor:
		Input.set_custom_mouse_cursor(crosshair_cursor, Input.CURSOR_ARROW, crosshair_cursor.get_size() / 2.0)

	_player = get_tree().get_first_node_in_group("player")
	_player_health = _player.get_node("Health")
	_saber_orbit = _player.get_node("SaberOrbit")
	_camera = get_tree().get_first_node_in_group("camera")

	if music:
		(music.stream as AudioStreamMP3).loop = true # Müzik hiç bitmesin

	# Ana menüyle aynı kaydedilmiş ses ayarı
	if volume_slider:
		volume_slider.set_value_no_signal(Settings.volume)
		volume_slider.value_changed.connect(set_volume)

	_update_level_text()


# ESC menüsündeki ses slider'ı; ana menüyle aynı ayarı kullanır
func set_volume(volume: float) -> void:
	Settings.volume = volume


func _process(delta: float) -> void:
	if not get_tree().paused:
		game_time += delta

	# Oyun bitmişse ya da seviye atlama ekranı açıksa ESC hiçbir işe yaramasın
	if _is_game_over or _is_leveling_up:
		return

	if Input.is_action_just_pressed("pause"):
		if _is_paused:
			resume_game()
		else:
			pause_game()


func pause_game() -> void:
	if pause_panel: pause_panel.visible = true
	get_tree().paused = true # Müzik de pausable olduğu için kendiliğinden durur
	_is_paused = true

	# ESC menüsü açıldığında HUD'u gizle
	_set_hud_visibility(false)


func resume_game() -> void:
	if pause_panel: pause_panel.visible = false
	get_tree().paused = false
	_is_paused = false

	# Oyuna devam edildiğinde HUD'u tekrar görünür yap
	_set_hud_visibility(true)


func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null) # Ana menüde (ve oyun kapanırken) normal imleç


func load_main_menu() -> void:
	get_tree().paused = false # Zamanı normale döndürmezsek ana menü de donuk kalır!
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func add_score(points: int) -> void:
	score += points
	_update_score_text()


func _update_score_text() -> void:
	if score_text:
		score_text.text = "SCORE: " + str(score)


func show_game_over() -> void:
	if _is_game_over:
		return

	_is_game_over = true
	if game_over_panel: game_over_panel.visible = true

	# Oyun bittiğinde Skor, Level ve Dash UI'ı gizle
	_set_hud_visibility(false)

	if music:
		music.stop()
		if game_over_sound:
			play_sound(game_over_sound, music.volume_linear)

	get_tree().paused = true


func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# Mermi ve kılıç isabeti: canı 1 azaltır, bittiyse öldürür. Düşman zaten öldüyse false döner.
func hit_enemy(enemy: Node) -> bool:
	if enemy == null or enemy.is_dead:
		return false
	if enemy.take_hit():
		kill_enemy(enemy)
	return true


# Mermi, kılıç ve bombanın ortak öldürme yolu. Düşman zaten öldüyse false döner.
func kill_enemy(enemy: Node, feedback := true) -> bool:
	if enemy == null or enemy.is_dead:
		return false
	enemy.is_dead = true

	var position: Vector2 = enemy.global_position
	add_score(10)

	if feedback:
		if _camera: _camera.trigger_shake(0.08, 0.08)
		# Unity'de PlayClipAtPoint kameradan ~10 birim uzakta çaldığı için kısık duyuluyordu
		if enemy_death_sound: play_sound(enemy_death_sound, 0.1)

	if xp_crystal_scene:
		var crystal: Node2D = xp_crystal_scene.instantiate()
		crystal.xp_value = enemy.xp_reward
		_spawn(crystal, position)

	_try_drop(multi_shot_pickup_scene, Settings.multi_shot_drop_chance(), position)
	_try_drop(magnet_pickup_scene, Settings.magnet_drop_chance(), position)
	# Kılıçlar doluysa (3) kılıç item'ı artık düşmesin
	if _saber_orbit == null or not _saber_orbit.is_full():
		_try_drop(saber_pickup_scene, Settings.saber_drop_chance(), position)

	if death_effect:
		_spawn(death_effect.instantiate(), position)

	enemy.queue_free()
	return true


func _try_drop(scene: PackedScene, chance: float, position: Vector2) -> void:
	if scene == null or randf() >= chance:
		return
	# XP kristaliyle üst üste binmesin diye biraz kaydır
	_spawn(scene.instantiate(), position + Vector2.from_angle(randf() * TAU) * 0.5 * Settings.UNIT)


# Fizik callback'i içinde sahneye node eklemek güvenli değil; bir sonraki kareye ertelenir
func _spawn(node: Node2D, position: Vector2) -> void:
	node.position = position
	get_parent().add_child.call_deferred(node)


func add_xp(amount: int) -> void:
	current_xp += amount

	_update_level_text()

	# Seviye ekranı açıkken gelen XP birikir; seçim yapılınca _resume_after_upgrade tekrar kontrol eder
	if not _is_leveling_up and current_xp >= xp_to_next_level:
		_level_up()


func _level_up() -> void:
	current_xp -= xp_to_next_level
	current_level += 1
	xp_to_next_level = current_level * 5

	_update_level_text()

	if level_up_panel:
		_is_leveling_up = true
		level_up_panel.visible = true

		_set_hud_visibility(false)

		if level_up_sound:
			play_sound(level_up_sound, 1.0)

		get_tree().paused = true


func _update_level_text() -> void:
	if level_text:
		level_text.text = "LEVEL: %d (XP: %d/%d)" % [current_level, current_xp, xp_to_next_level]


func choose_speed_upgrade() -> void:
	_player.increase_speed(1.0)
	_resume_after_upgrade()


func choose_fire_rate_upgrade() -> void:
	_player.increase_fire_rate(0.015)
	_resume_after_upgrade()


func choose_heal_upgrade() -> void:
	_player_health.heal_player()
	_resume_after_upgrade()


func _resume_after_upgrade() -> void:
	_is_leveling_up = false
	if level_up_panel: level_up_panel.visible = false

	_set_hud_visibility(true)

	get_tree().paused = false

	if current_xp >= xp_to_next_level:
		_level_up()


# Skor, Level ve Dash UI'ını birlikte gösterip gizler
func _set_hud_visibility(is_visible: bool) -> void:
	if score_text: score_text.visible = is_visible
	if level_text: level_text.visible = is_visible
	_player.set_dash_ui_visibility(is_visible)


# Unity'deki AudioSource.PlayClipAtPoint karşılığı; pause'da da çalar
func play_sound(stream: AudioStream, volume: float) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_linear = volume
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
