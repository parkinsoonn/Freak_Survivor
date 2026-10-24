extends Line2D

# Unity TrailRenderer karşılığı: ebeveynin geçtiği yerlere nokta bırakır, noktalar `lifetime` sonunda söner.
# Genişlik ve renk geçişi Line2D'nin width_curve / gradient ayarlarından gelir (baş = en yeni nokta).

@export var lifetime := 0.2
@export var min_vertex_distance := 3.2 # piksel (Unity: 0.05 birim)
@export var emitting := true

var _times: Array[float] = []
var _clock := 0.0


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	global_rotation = 0.0


func _process(delta: float) -> void:
	_clock += delta

	while _times.size() > 0 and _clock - _times[0] > lifetime:
		_times.pop_front()
		remove_point(0)

	if not emitting:
		return

	var head: Vector2 = get_parent().global_position
	if get_point_count() == 0 or get_point_position(get_point_count() - 1).distance_to(head) >= min_vertex_distance:
		add_point(head)
		_times.append(_clock)
	else:
		set_point_position(get_point_count() - 1, head)
