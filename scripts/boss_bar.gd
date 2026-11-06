extends Control

# Ekranın üstündeki boss can barı: sahnede boss varken görünür, yokken gizlenir

@export var bar: Range


func _process(_delta: float) -> void:
	var boss := get_tree().get_first_node_in_group("boss")
	visible = boss != null and not boss.is_dead
	if visible:
		bar.value = float(boss.health) / boss.max_health * 100.0
