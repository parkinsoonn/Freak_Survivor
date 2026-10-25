extends Area2D

enum PowerUpType { MULTI_SHOT, MAGNET, SABER }

# Düşmanlardan düşen item'lar; etkisi oyuncu ölene kadar kalır
@export var type := PowerUpType.MULTI_SHOT


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	match type:
		PowerUpType.MULTI_SHOT:
			body.add_bullet()
		PowerUpType.MAGNET:
			for gold in get_tree().get_nodes_in_group("gold"):
				gold.attract(body)
		PowerUpType.SABER:
			body.get_node("SaberOrbit").add_saber()
	queue_free()
