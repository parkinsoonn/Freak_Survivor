extends Node

# Wave döngüsü: INTRO (banner) → FIGHT (süre sayar, spawner açık) → CLEANUP (kalan moblar silinir,
# toplanmayan altınlar kaybolur) → SHOP (ağaç durur, market açık) → "SONRAKİ WAVE" ile tekrar INTRO

enum State { INTRO, FIGHT, CLEANUP, SHOP }

## Moblar silindikten sonra ölüm efektleri görünsün diye market açılmadan beklenen süre
const CLEANUP_TIME := 1.0

@export var spawner: Node
@export var wave_text: Label # Üst ortada "WAVE 3  0:24"
@export var shop_panel: Control

@export_group("Wave Banner'ı")
@export var banner: TextureRect
@export var banner_text: Label

var wave := 0
var state := State.INTRO
var time_left := 0.0

var _game_manager: Node


func _enter_tree() -> void:
	add_to_group("wave_manager")


func _ready() -> void:
	_game_manager = get_tree().get_first_node_in_group("game_manager")
	_start_next_wave()


static func wave_duration(number: int) -> float:
	return minf(20.0 + 5.0 * (number - 1), 60.0)


func _process(delta: float) -> void:
	if state != State.FIGHT:
		return

	time_left = maxf(time_left - delta, 0.0)
	_update_wave_text()
	if time_left <= 0.0:
		_end_wave()


func _start_next_wave() -> void:
	wave += 1
	state = State.INTRO
	time_left = wave_duration(wave)
	_update_wave_text()

	await _play_banner()

	state = State.FIGHT
	spawner.start_wave(wave, time_left)


# "WAVE N" soldan kayarak girer, ~1 sn bekler, sağa çıkar
func _play_banner() -> void:
	banner_text.text = tr("DALGA %d") % wave
	var width := banner.get_viewport_rect().size.x
	banner.position.x = -banner.size.x
	banner.visible = true

	# Girişte wave_banner_sheet "intro" kareleri (7 x 60 ms) oynar
	var atlas := banner.texture as AtlasTexture
	var tween := create_tween().set_trans(Tween.TRANS_BACK)
	tween.tween_property(banner, "position:x", (width - banner.size.x) / 2.0, 0.45).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(func(f: float) -> void: atlas.region.position.x = floorf(f) * atlas.region.size.x, 0.0, 6.99, 0.42)
	tween.tween_interval(1.0)
	tween.tween_property(banner, "position:x", width, 0.35).set_ease(Tween.EASE_IN)
	await tween.finished
	banner.visible = false


func _end_wave() -> void:
	state = State.CLEANUP
	spawner.stop()

	# Kalan moblar ölüm efektiyle silinir; skor ve altın vermez
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_game_manager.kill_enemy(enemy, false, false)

	# Toplanmayan altınlar sönerek kaybolur; son karede öldürülenlerinki ertelenmiş eklendiği için bir kare bekle
	await get_tree().process_frame
	for coin in get_tree().get_nodes_in_group("gold"):
		coin.remove_from_group("gold") # Sönerken toplanmasın
		coin.set_deferred("monitoring", false)
		var tween := coin.create_tween()
		tween.tween_property(coin, "modulate:a", 0.0, 0.3)
		tween.tween_callback(coin.queue_free)

	await get_tree().create_timer(CLEANUP_TIME, false).timeout

	state = State.SHOP
	_game_manager.set_hud_visibility(false)
	get_tree().paused = true
	shop_panel.open()


# Marketteki "SONRAKİ WAVE" butonu
func next_wave() -> void:
	if state != State.SHOP:
		return
	state = State.INTRO # Kapanış animasyonu sırasında ikinci tık yok sayılsın

	await shop_panel.close()
	get_tree().paused = false
	_game_manager.set_hud_visibility(true)
	_start_next_wave()


func can_pause() -> bool:
	return state == State.FIGHT


func _update_wave_text() -> void:
	if wave_text:
		var seconds := ceili(time_left)
		wave_text.text = (tr("DALGA %d") % wave) + "  %d:%02d" % [floori(seconds / 60.0), seconds % 60]
