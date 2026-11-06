extends Area2D

# Nişancı mermisi: düz uçar, oyuncuya çarparsa 1 hasar verir (bariyer/dash i-frame'i Health'te geçerli)

## Uçuş hızı (birim/sn); oyuncu kaçabilsin diye yavaş
@export var speed := 6.0

var direction := Vector2.DOWN

var _life := 4.0


func _enter_tree() -> void:
	add_to_group("enemy_bullet") # Dalga sonunda temizlenir


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * Settings.UNIT * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.get_node("Health").take_damage(1)
		queue_free()
