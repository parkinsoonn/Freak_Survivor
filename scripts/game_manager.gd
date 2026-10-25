extends Node

# Pause altında da çalışır (process_mode = Always): ESC ve panel butonları için

@export_group("UI Panelleri")
@export var game_over_panel: Control
@export var game_over_wave_text: Label # Game Over'da ulaşılan wave
@export var pause_panel: Control

@export_group("Skor Sistemi")
@export var score := 0
@export var score_text: Label

@export_group("Altın")
@export var gold := 0
@export var gold_counter: Control # Sağ üstteki coin ikonu + sayı
@export var gold_text: Label

@export_group("ESC Menüsü")
@export var volume_slider: Range

@export_group("Ses Ayarları")
@export var game_over_sound: AudioStream
@export var music: AudioStreamPlayer

@export_group("Düşman Ölümü ve Drop'lar")
@export var death_effect: PackedScene
@export var enemy_death_sound: AudioStream
@export var gold_scene: PackedScene
@export var multi_shot_pickup_scene: PackedScene
@export var magnet_pickup_scene: PackedScene
@export var saber_pickup_scene: PackedScene

@export_group("İmleç")
@export var crosshair_cursor: Texture2D

# Oyun durumunu kontrol eden kilitler
var _is_paused := false
var _is_game_over := false

var _player: Node
var _camera: Node
var _saber_orbit: Node
var _wave_manager: Node


func _enter_tree() -> void:
	add_to_group("game_manager")


func _ready() -> void:
	get_tree().paused = false
	_update_score_text()
	_update_gold_text()
	# Nişangah 2x piksel-keskin büyütülür, hotspot ortası
	if crosshair_cursor:
		var img := crosshair_cursor.get_image()
		img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(img), Input.CURSOR_ARROW, img.get_size() / 2.0)

	_player = get_tree().get_first_node_in_group("player")
	_saber_orbit = _player.get_node("SaberOrbit")
	_camera = get_tree().get_first_node_in_group("camera")
	_wave_manager = get_tree().get_first_node_in_group("wave_manager")

	if music:
		(music.stream as AudioStreamMP3).loop = true # Müzik hiç bitmesin

	# Ana menüyle aynı kaydedilmiş ses ayarı
	if volume_slider:
		volume_slider.set_value_no_signal(Settings.volume)
		volume_slider.value_changed.connect(set_volume)


# ESC menüsündeki ses slider'ı; ana menüyle aynı ayarı kullanır
func set_volume(volume: float) -> void:
	Settings.volume = volume


func _process(_delta: float) -> void:
	# Oyun bitmişse, market ya da wave geçişi sırasında ESC hiçbir işe yaramasın
	if _is_game_over or not _wave_manager.can_pause():
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
	set_hud_visibility(false)


func resume_game() -> void:
	if pause_panel: pause_panel.visible = false
	get_tree().paused = false
	_is_paused = false

	# Oyuna devam edildiğinde HUD'u tekrar görünür yap
	set_hud_visibility(true)


func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null) # Ana menüde (ve oyun kapanırken) normal imleç


func load_main_menu() -> void:
	Transition.change_scene("res://scenes/main_menu.tscn")


func add_score(points: int) -> void:
	score += points
	_update_score_text()


func _update_score_text() -> void:
	if score_text:
		score_text.text = "SCORE: " + str(score)


func add_gold(amount: int) -> void:
	gold += amount
	_update_gold_text()

	# Sayı kısa bir ölçek "pop"u yapar
	if gold_text:
		gold_text.pivot_offset = gold_text.size / 2.0
		var tween := gold_text.create_tween()
		gold_text.scale = Vector2(1.4, 1.4)
		tween.tween_property(gold_text, "scale", Vector2.ONE, 0.15)


func _update_gold_text() -> void:
	if gold_text:
		gold_text.text = str(gold)


func show_game_over() -> void:
	if _is_game_over:
		return

	_is_game_over = true
	if game_over_panel: game_over_panel.visible = true
	if game_over_wave_text: game_over_wave_text.text = "WAVE %d" % _wave_manager.wave

	# Oyun bittiğinde HUD'u gizle
	set_hud_visibility(false)

	if music:
		music.stop()
		if game_over_sound:
			play_sound(game_over_sound, music.volume_linear)

	get_tree().paused = true


func restart_game() -> void:
	Transition.change_scene(get_tree().current_scene.scene_file_path)


# Mermi ve kılıç isabeti: canı 1 azaltır, bittiyse öldürür. Düşman zaten öldüyse false döner.
func hit_enemy(enemy: Node) -> bool:
	if enemy == null or enemy.is_dead:
		return false
	if enemy.take_hit():
		kill_enemy(enemy)
	return true


# Mermi, kılıç, bomba ve wave sonu temizliğinin ortak öldürme yolu. Düşman zaten öldüyse false döner.
# reward = false: skor ve drop yok, sadece ölüm efekti (wave bitince kalan moblar)
func kill_enemy(enemy: Node, feedback := true, reward := true) -> bool:
	if enemy == null or enemy.is_dead:
		return false
	enemy.is_dead = true

	var position: Vector2 = enemy.global_position

	if feedback:
		if _camera: _camera.trigger_shake(0.08, 0.08)
		# Unity'de PlayClipAtPoint kameradan ~10 birim uzakta çaldığı için kısık duyuluyordu
		if enemy_death_sound: play_sound(enemy_death_sound, 0.1)

	if reward:
		add_score(10)

		if gold_scene:
			var coin: Node2D = gold_scene.instantiate()
			coin.value = enemy.gold_reward
			_spawn(coin, position)

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
	# Altınla üst üste binmesin diye biraz kaydır
	_spawn(scene.instantiate(), position + Vector2.from_angle(randf() * TAU) * 0.5 * Settings.UNIT)


# Fizik callback'i içinde sahneye node eklemek güvenli değil; bir sonraki kareye ertelenir
func _spawn(node: Node2D, position: Vector2) -> void:
	node.position = position
	get_parent().add_child.call_deferred(node)


# Skor, altın, wave ve Dash UI'ını birlikte gösterip gizler
func set_hud_visibility(is_visible: bool) -> void:
	if score_text: score_text.visible = is_visible
	if gold_counter: gold_counter.visible = is_visible
	if _wave_manager.wave_text: _wave_manager.wave_text.visible = is_visible
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
