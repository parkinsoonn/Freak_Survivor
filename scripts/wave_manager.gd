extends Node

# Wave döngüsü: INTRO (banner) → FIGHT (süre sayar, spawner açık) → CLEANUP (kalan moblar silinir,
# altınlar oyuncuya uçar) → SHOP (ağaç durur, market açık) → "SONRAKİ WAVE" ile tekrar INTRO

enum State { INTRO, FIGHT, CLEANUP, SHOP }

## Moblar silindikten sonra altınların oyuncuya uçması için beklenen süre
const CLEANUP_TIME := 1.0

@export var spawner: Node
@export var wave_text: Label # Üst ortada "WAVE 3  0:24"
@export var shop_panel: Control

var wave := 0
var state := State.INTRO
var time_left := 0.0

var _game_manager: Node
var _player: Node2D


func _enter_tree() -> void:
	add_to_group("wave_manager")


func _ready() -> void:
	_game_manager = get_tree().get_first_node_in_group("game_manager")
	_player = get_tree().get_first_node_in_group("player")
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

	await get_tree().create_timer(1.0, false).timeout

	state = State.FIGHT
	spawner.start_wave(wave, time_left)


func _end_wave() -> void:
	state = State.CLEANUP
	spawner.stop()

	# Kalan moblar ölüm efektiyle silinir; skor ve altın vermez
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_game_manager.kill_enemy(enemy, false, false)

	# Son karede öldürülenlerin altını ertelenmiş eklenir, bir kare bekleyip hepsini çek
	await get_tree().process_frame
	for coin in get_tree().get_nodes_in_group("gold"):
		coin.attract(_player)

	await get_tree().create_timer(CLEANUP_TIME, false).timeout

	# Yetişemeyen uzaktaki altınlar da sayılsın
	for coin in get_tree().get_nodes_in_group("gold"):
		_game_manager.add_gold(coin.value)
		coin.queue_free()

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
		wave_text.text = "WAVE %d  %d:%02d" % [wave, floori(seconds / 60.0), seconds % 60]
