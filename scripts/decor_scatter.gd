extends Node2D

# Zemin dekorlarını kameranın çevresindeki 3x3 chunk'a serpiştirir. Her chunk'ın dekoru chunk
# koordinatından türetilen seed'le belirlenir: aynı yere dönünce aynı dekor görünür.
# Nesneler havuzlanır; chunk'tan çıkan dekor gizlenip yeni chunk'ta yeniden kullanılır.

## Her animasyon bir dekor (balcik 4 kare, diğerleri tek kare)
@export var decor_frames: SpriteFrames
## Chunk kenarı, birim
@export var chunk_size := 10.0
@export var min_per_chunk := 2
@export var max_per_chunk := 5
## 10x export edilmiş dekorlar zemin yoğunluğunda (16 çizim pikseli = 1.25 birim)
@export var decor_scale := 0.5

var _active := {} # Vector2i -> Array[AnimatedSprite2D]
var _pool: Array[AnimatedSprite2D] = []


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null or decor_frames == null:
		return

	var size := chunk_size * Settings.UNIT
	var center := Vector2i((camera.global_position / size).floor())
	var wanted := {}
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			wanted[center + Vector2i(dx, dy)] = true

	for chunk in _active.keys():
		if not wanted.has(chunk):
			_release(chunk)
	for chunk in wanted:
		if not _active.has(chunk):
			_fill(chunk, size)


func _fill(chunk: Vector2i, size: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = (chunk.x * 73856093) ^ (chunk.y * 19349663)

	var names := decor_frames.get_animation_names()
	# Zemindeki bir çizim pikseli; dekorlar bu ızgaraya oturur ki tuğlalarla hizalı kalsın
	var pixel := Settings.UNIT * 1.25 / 16.0
	var decors: Array[AnimatedSprite2D] = []
	for i in rng.randi_range(min_per_chunk, max_per_chunk):
		var decor := _take()
		decor.play(names[rng.randi() % names.size()])
		decor.position = (Vector2(chunk) * size + Vector2(rng.randf(), rng.randf()) * size).snapped(Vector2(pixel, pixel))
		decor.rotation = rng.randi_range(0, 3) * PI / 2.0
		decor.visible = true
		decors.append(decor)
	_active[chunk] = decors


func _take() -> AnimatedSprite2D:
	if not _pool.is_empty():
		return _pool.pop_back()

	var decor := AnimatedSprite2D.new()
	decor.sprite_frames = decor_frames
	decor.scale = Vector2(decor_scale, decor_scale)
	add_child(decor)
	return decor


func _release(chunk: Vector2i) -> void:
	for decor in _active[chunk]:
		decor.stop()
		decor.visible = false
		_pool.append(decor)
	_active.erase(chunk)
