extends "res://scripts/enemy_controller.gd"

# Golem (mini boss): oyuncu slam_range içindeyse slam_interval'de bir durur, windup boyunca kırmızı yanıp söner,
# sonra oyuncunun bulunduğu yere blast_step arayla blast_count yer patlaması atar.

@export var blast_scene: PackedScene
@export var slam_interval := 5.0
## Oyuncu bundan (birim) uzaktaysa saldırmaz (ekran dışından vurmasın)
@export var slam_range := 8.0
@export var windup := 0.5
@export var blast_count := 3
@export var blast_step := 0.3

var _slam_timer := 2.0 # Belirir belirmez saldırmasın
var _windup_left := 0.0
var _blasts_left := 0
var _blast_wait := 0.0
var _walk_speed := 0.0


func _ready() -> void:
	super()
	_walk_speed = speed


func _process(delta: float) -> void:
	if _player == null or is_dead or blast_scene == null:
		return

	if _windup_left > 0.0:
		_windup_left -= delta
		_visual.modulate = Color(2.0, 0.5, 0.5) if int(_windup_left * 16.0) % 2 == 0 else Color.WHITE
		if _windup_left <= 0.0:
			_visual.modulate = Color.WHITE
			_blasts_left = blast_count
			_blast_wait = 0.0
		return

	if _blasts_left > 0:
		_blast_wait -= delta
		if _blast_wait <= 0.0:
			var blast: Node2D = blast_scene.instantiate()
			blast.global_position = _player.global_position
			get_parent().add_child(blast)
			_blasts_left -= 1
			_blast_wait = blast_step
			if _blasts_left == 0:
				speed = _walk_speed
				_slam_timer = slam_interval
		return

	_slam_timer -= delta
	var range_px := slam_range * Settings.UNIT
	if _slam_timer <= 0.0 and global_position.distance_squared_to(_player.global_position) < range_px * range_px:
		speed = 0.0
		_windup_left = windup
