extends Node2D

# Yer patlaması (boss/golem saldırısı): delay boyunca kırmızı uyarı dairesi dolar, sonra patlar;
# oyuncu radius içindeyse 1 hasar alır. Ağaç duraklayınca (market/pause) uyarı da durur.

@export var delay := 0.7
## Patlama yarıçapı (birim)
@export var radius := 1.6

var _time := 0.0
var _player: Node2D


func _enter_tree() -> void:
	add_to_group("enemy_bullet") # Dalga sonunda temizlenir


func _ready() -> void:
	z_index = -1 # Düşmanların altında, zeminin üstünde
	_player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	_time += delta
	if _time >= delay:
		_explode()
		return
	queue_redraw()


func _draw() -> void:
	var r := radius * Settings.UNIT
	var fill := clampf(_time / delay, 0.0, 1.0)
	draw_circle(Vector2.ZERO, r, Color(0.88, 0.28, 0.28, 0.18))
	draw_circle(Vector2.ZERO, r * fill, Color(0.88, 0.28, 0.28, 0.35))
	# Son anlarda kenar hızla yanıp söner
	var blink := fill > 0.7 and int(_time * 20.0) % 2 == 0
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 0.9, 0.8) if blink else Color(0.88, 0.28, 0.28), 4.0)


func hits_player() -> bool:
	if _player == null:
		return false
	var r := radius * Settings.UNIT
	return global_position.distance_squared_to(_player.global_position) < r * r


func _explode() -> void:
	if hits_player():
		_player.get_node("Health").take_damage(1)

	var camera := get_tree().get_first_node_in_group("camera")
	if camera: camera.trigger_shake(0.15, 0.15)
	# Patlayan düşmanınki gibi: ölüm efektinin büyük, turuncu hali
	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.death_effect:
		var fx: Node2D = game_manager.death_effect.instantiate()
		fx.global_position = global_position
		fx.scale *= 2.5
		fx.modulate = Color(1.0, 0.55, 0.2)
		get_parent().add_child(fx)
	queue_free()
