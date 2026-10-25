extends Area2D

# Düşmanlardan düşen mıknatıs: yerdeki tüm altınları oyuncuya çeker


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	for gold in get_tree().get_nodes_in_group("gold"):
		gold.attract(body)
	queue_free()
