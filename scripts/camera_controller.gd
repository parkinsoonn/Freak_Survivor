extends Camera2D

@export var target: Node2D
@export var smooth_speed := 5.0

## Zeminin bir çizim pikseli, dünya pikseli (1.25 birim = 16 çizim pikseli)
const ART_PIXEL := Settings.UNIT * 1.25 / 16.0

var _shake_duration := 0.0
var _shake_magnitude := 0.0
var _base_position := Vector2.ZERO
var _base_zoom := 1.0


func _enter_tree() -> void:
	add_to_group("camera")


func _ready() -> void:
	_base_position = global_position
	_base_zoom = zoom.x
	_snap_zoom()
	get_viewport().size_changed.connect(_snap_zoom)


# Çizim pikseli ekranda tam sayı piksel olsun diye zoom en yakın değere çekilir; yoksa nearest
# filtrede bazı sütunlar 1 piksel kalın çıkar ve kamera kayarken bu dikiş desenin üstünde gezer
func _snap_zoom() -> void:
	var stretch := get_viewport().get_final_transform().x.x
	var screen_pixels := maxf(roundf(ART_PIXEL * _base_zoom * stretch), 1.0)
	zoom = Vector2.ONE * screen_pixels / (ART_PIXEL * stretch)


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
