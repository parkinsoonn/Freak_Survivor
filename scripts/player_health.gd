extends Node

# Oyuncunun (ebeveyn RigidBody2D) canı; düşmana temas ettikçe hasar alır

@export var max_health := 4
var current_health := 0

## Hasar aldıktan sonra tekrar hasar alınmayan süre (saniye)
@export var hit_invincibility_duration := 0.5
var _invincible_timer := 0.0

@export_group("UI Ayarları")
## Can barı; value = can yüzdesi (0-100)
@export var health_bar: TextureProgressBar
## Dolgu dokuları: %60 üstü, %30-60, %30 altı (health_bar_sheet: yeşil, altın, kırmızı)
@export var fill_textures: Array[Texture2D] = []

var is_invincible := false

var _game_manager: Node
@onready var _body: RigidBody2D = get_parent()


func _ready() -> void:
	current_health = max_health
	_update_health_ui()

	_game_manager = get_tree().get_first_node_in_group("game_manager")
	_body.contact_monitor = true
	_body.max_contacts_reported = 8


func _physics_process(delta: float) -> void:
	_invincible_timer -= delta

	# Unity'deki OnCollisionEnter/Stay: düşman yapışık kaldıkça (i-frame bitince) hasar vermeye devam etsin
	for body in _body.get_colliding_bodies():
		if body.is_in_group("enemy"):
			take_damage(1)
			break


func take_damage(damage_amount: int) -> void:
	if is_invincible or current_health <= 0 or _invincible_timer > 0.0:
		return

	_invincible_timer = hit_invincibility_duration

	current_health = clampi(current_health - damage_amount, 0, max_health)
	_update_health_ui()

	if current_health <= 0:
		if _game_manager:
			_game_manager.show_game_over()
		_die()


func heal_player(amount: int) -> void:
	current_health = mini(current_health + amount, max_health)
	_update_health_ui()


# Yeni kapasite dolu gelir
func increase_max_health(amount: int) -> void:
	max_health += amount
	current_health += amount
	_update_health_ui()


# Bar can oranı kadar dolar; renk orana göre yeşil → altın → kırmızı
func _update_health_ui() -> void:
	if health_bar:
		var ratio := float(current_health) / max_health
		health_bar.value = 100.0 * ratio
		if fill_textures.size() == 3:
			health_bar.texture_progress = fill_textures[0 if ratio > 0.6 else 1 if ratio > 0.3 else 2]


func _die() -> void:
	# Oyuncu kontrolünü kapat ve yerinde durdur
	_body.set_process(false)
	_body.set_physics_process(false)
	_body.linear_velocity = Vector2.ZERO
