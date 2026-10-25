extends RigidBody2D

# Değerler Unity birimiyle (1 birim = Settings.UNIT piksel)
@export var speed := 3.0
## Oyuncudan bu mesafeden fazla uzaklaşan düşman silinir
@export var despawn_distance := 30.0
## Ölmesi için gereken mermi sayısı
@export var health := 1
## Ölünce düşen altının değeri
@export var gold_reward := 1

# Aynı karede birden fazla mermi çarparsa ödülün tek kez verilmesi için
var is_dead := false

var _player: Node2D
# Sprite ve collider oyuncuya döner; gövde kilitli kalır (Unity'de rb2d.rotation)
@onready var _visual: Node2D = $Visual
@onready var _shape: CollisionShape2D = $Shape
@onready var _shape_offset: Vector2 = _shape.position


func _enter_tree() -> void:
	add_to_group("enemy")


func _ready() -> void:
	gravity_scale = 0.0
	lock_rotation = true

	# Zorluk çarpanı + wave ilerledikçe artan hız bonusu
	var wave_manager := get_tree().get_first_node_in_group("wave_manager")
	var wave: int = wave_manager.wave if wave_manager else 1
	var wave_bonus := minf(Settings.max_speed_bonus(), Settings.speed_growth_per_wave() * (wave - 1))
	speed *= Settings.enemy_speed_multiplier() * (1.0 + wave_bonus)

	_player = get_tree().get_first_node_in_group("player")


# Mermi isabeti: canı 1 azaltır, ölmediyse kısa kırmızı yanıp sönme; öldüyse true döner
func take_hit() -> bool:
	health -= 1
	if health > 0:
		_hit_flash()
		return false
	return true


func _hit_flash() -> void:
	_visual.modulate = Color(1.0, 0.4, 0.4)
	await get_tree().create_timer(0.1, false).timeout
	if is_instance_valid(self):
		_visual.modulate = Color.WHITE


func _physics_process(_delta: float) -> void:
	if _player == null:
		return

	var to_player := _player.global_position - global_position
	var despawn := despawn_distance * Settings.UNIT
	if to_player.length_squared() > despawn * despawn:
		queue_free()
		return

	var direction := to_player.normalized()
	linear_velocity = direction * speed * Settings.UNIT

	# Görselin alt kenarı (yüzü) oyuncuya baksın
	var angle := direction.angle() - PI / 2.0
	_visual.rotation = angle
	_shape.rotation = angle
	_shape.position = _shape_offset.rotated(angle)
