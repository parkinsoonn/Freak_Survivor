extends Sprite2D

# Döşenmiş zemin, kendi karo boyutunun katlarında kameraya yapışır; böylece kayma görünmez

@export var tile_size := Vector2(80, 80) # 1 karo, piksel (antrasit_zemin: 1.25 birim)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return

	global_position = (camera.global_position / tile_size).round() * tile_size
