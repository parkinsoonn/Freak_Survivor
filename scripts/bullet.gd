extends Area2D

## Merminin uçuş hızı (birim/sn)
@export var speed := 20.0

var direction := Vector2.UP

var _has_hit := false
var _life := 3.0
var _game_manager: Node


func _ready() -> void:
	_game_manager = get_tree().get_first_node_in_group("game_manager")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * Settings.UNIT * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if _has_hit or _game_manager == null or not body.is_in_group("enemy"):
		return

	# Bu düşmanı aynı karede başka bir mermi zaten öldürdüyse mermi boşa harcanmasın
	if _game_manager.hit_enemy(body):
		_has_hit = true
		queue_free()
