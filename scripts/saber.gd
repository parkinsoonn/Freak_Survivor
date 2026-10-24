extends Area2D

# Dönen ışın kılıcı; her teması mermi gibi 1 vuruş sayılır

var _game_manager: Node


func _ready() -> void:
	_game_manager = get_tree().get_first_node_in_group("game_manager")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _game_manager and body.is_in_group("enemy"):
		_game_manager.hit_enemy(body)
