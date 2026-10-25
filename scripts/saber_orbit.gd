extends Node2D

# Marketten alınan her ışın kılıcı oyuncunun etrafında eşit aralıklarla döner.
# Oyuncu gövdesi dönmediği (sadece görseli döndüğü) için bu node doğrudan oyuncunun çocuğu olabilir.

@export var saber_scene: PackedScene
@export var radius := 1.5
@export var rotate_speed := 220.0 # derece/sn
@export var saber_size := 1.0 # Sprite + collider ölçeği

var _sabers: Array[Node2D] = []


func add_saber(amount: int) -> void:
	if saber_scene == null:
		return

	for i in amount:
		var saber: Node2D = saber_scene.instantiate()
		add_child(saber)
		_sabers.append(saber)
	_layout()


func increase_rotate_speed(amount: float) -> void:
	rotate_speed += amount


func increase_saber_size(amount: float) -> void:
	saber_size += amount
	_layout()


func increase_radius(amount: float) -> void:
	radius += amount
	_layout()


# Hepsini eşit açılarla yeniden diz, bıçaklar dışa baksın
func _layout() -> void:
	for i in _sabers.size():
		var angle := TAU / _sabers.size() * i
		_sabers[i].position = Vector2.UP.rotated(angle) * radius * Settings.UNIT
		_sabers[i].rotation = angle
		_sabers[i].scale = Vector2.ONE * saber_size


func _process(delta: float) -> void:
	# Unity'de saat yönünde dönüyordu; Godot'ta pozitif açı saat yönü
	rotation += deg_to_rad(rotate_speed) * delta
