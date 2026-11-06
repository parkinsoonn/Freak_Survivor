extends "res://scripts/enemy_controller.gd"

# Patlayan: oyuncuya trigger_distance kadar yaklaşınca durur, fuse_time boyunca kırmızı yanıp söner,
# sonra patlar; oyuncu explosion_radius içindeyse 1 hasar alır. Fitil yanarken vurulursa normal ölür.

@export var trigger_distance := 1.5
@export var fuse_time := 0.6
@export var explosion_radius := 2.0

var _fuse := -1.0 # -1 = fitil yanmadı


func _process(delta: float) -> void:
	if _player == null or is_dead:
		return

	if _fuse < 0.0:
		var trigger := trigger_distance * Settings.UNIT
		if global_position.distance_squared_to(_player.global_position) < trigger * trigger:
			_fuse = 0.0
			speed = 0.0
		return

	_fuse += delta
	_visual.modulate = Color(2.0, 0.5, 0.5) if int(_fuse * 16.0) % 2 == 0 else Color.WHITE
	if _fuse >= fuse_time:
		_explode()


func _explode() -> void:
	var radius := explosion_radius * Settings.UNIT
	if global_position.distance_squared_to(_player.global_position) < radius * radius:
		_player.get_node("Health").take_damage(1)

	var game_manager := get_tree().get_first_node_in_group("game_manager")
	var camera := get_tree().get_first_node_in_group("camera")
	if camera: camera.trigger_shake(0.25, 0.25)
	# Normal ölüm efektinin büyük, turuncu hali
	if game_manager.death_effect:
		var fx: Node2D = game_manager.death_effect.instantiate()
		fx.global_position = global_position
		fx.scale *= 3.0
		fx.modulate = Color(1.0, 0.55, 0.2)
		get_parent().add_child(fx)
	# Kendi patlaması skor/altın vermez
	game_manager.kill_enemy(self, true, false)
