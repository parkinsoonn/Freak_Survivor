extends Area2D

@export var value := 1

var _game_manager: Node

# Toplama alanına girince ya da mıknatısla oyuncuya doğru hızlanarak uçar; toplama yine body_entered ile olur
var _attract_target: Node2D
var _attract_speed := 4.0


func _ready() -> void:
	add_to_group("gold")
	_game_manager = get_tree().get_first_node_in_group("game_manager")
	body_entered.connect(_on_body_entered)


func attract(target: Node2D) -> void:
	_attract_target = target


func _process(delta: float) -> void:
	if not is_instance_valid(_attract_target):
		return

	_attract_speed += 30.0 * delta
	global_position = global_position.move_toward(_attract_target.global_position, _attract_speed * Settings.UNIT * delta)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if _game_manager:
			_game_manager.add_gold(value)
		queue_free()
