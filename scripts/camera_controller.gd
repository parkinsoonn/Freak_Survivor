extends Camera2D

@export var target: Node2D
@export var smooth_speed := 5.0

var _shake_duration := 0.0
var _shake_magnitude := 0.0
var _base_position := Vector2.ZERO


func _enter_tree() -> void:
	add_to_group("camera")


func _ready() -> void:
	_base_position = global_position


# magnitude Unity birimiyle
func trigger_shake(duration: float, magnitude: float) -> void:
	_shake_duration = duration
	_shake_magnitude = magnitude


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	# Üstel yumuşatma: kare hızından bağımsız aynı takip hissi
	_base_position = _base_position.lerp(target.global_position, 1.0 - exp(-smooth_speed * delta))

	var shake_offset := Vector2.ZERO
	if _shake_duration > 0.0:
		shake_offset = Vector2.from_angle(randf() * TAU) * sqrt(randf()) * _shake_magnitude * Settings.UNIT
		_shake_duration -= delta

	global_position = _base_position + shake_offset
