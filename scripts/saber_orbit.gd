extends Node2D

# Toplanan her ışın kılıcı oyuncunun etrafında eşit aralıklarla döner.
# Oyuncu gövdesi dönmediği (sadece görseli döndüğü) için bu node doğrudan oyuncunun çocuğu olabilir.

@export var saber_scene: PackedScene
@export var radius := 1.5
@export var rotate_speed := 220.0 # derece/sn
@export var max_sabers := 3

var _sabers: Array[Node2D] = []


func is_full() -> bool:
	return _sabers.size() >= max_sabers


func add_saber() -> void:
	if saber_scene == null or is_full():
		return

	var saber: Node2D = saber_scene.instantiate()
	add_child(saber)
	_sabers.append(saber)

	# Hepsini eşit açılarla yeniden diz, bıçaklar dışa baksın
	for i in _sabers.size():
		var angle := TAU / _sabers.size() * i
		_sabers[i].position = Vector2.UP.rotated(angle) * radius * Settings.UNIT
		_sabers[i].rotation = angle


func _process(delta: float) -> void:
	# Unity'de saat yönünde dönüyordu; Godot'ta pozitif açı saat yönü
	rotation += deg_to_rad(rotate_speed) * delta
