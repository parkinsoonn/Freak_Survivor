extends Control

# Wave arası market; ağaç durmuşken çalışır (UI process_mode = Always)

const SLIDE_TIME := 0.3
const SLIDE_OFFSET := 120.0


# Aşağıdan kayarak + fade ile gelir
func open() -> void:
	visible = true
	await _slide(SLIDE_OFFSET, 0.0, 0.0, 1.0)


# Kapanırken tersi
func close() -> void:
	await _slide(0.0, SLIDE_OFFSET, 1.0, 0.0)
	visible = false


func _slide(from_y: float, to_y: float, from_alpha: float, to_alpha: float) -> void:
	position.y = from_y
	modulate.a = from_alpha
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", to_y, SLIDE_TIME)
	tween.tween_property(self, "modulate:a", to_alpha, SLIDE_TIME)
	await tween.finished
