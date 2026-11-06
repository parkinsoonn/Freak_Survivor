extends "res://scripts/enemy_controller.gd"

# Nişancı: stop_distance mesafesinde durur, fire_interval'de bir oyuncuya mermi atar

@export var bullet_scene: PackedScene
@export var fire_interval := 2.0
## Oyuncu bundan (birim) uzaktayken ateş etmez (ekran dışından vurmasın)
@export var fire_range := 9.0

# Hepsi aynı anda ateş etmesin
var _fire_timer := randf_range(0.8, 1.6)


func _process(delta: float) -> void:
	if _player == null or is_dead or bullet_scene == null:
		return

	_fire_timer -= delta
	if _fire_timer > 0.0:
		return

	var to_player := _player.global_position - global_position
	var fire_px := fire_range * Settings.UNIT
	if to_player.length_squared() > fire_px * fire_px:
		return

	_fire_timer = fire_interval
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = to_player.normalized()
	get_parent().add_child(bullet)
