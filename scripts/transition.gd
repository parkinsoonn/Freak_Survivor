extends CanvasLayer

# Sahne geçişlerinde siyaha fade (autoload: Transition). Her şeyin üstünde, pause'da da çalışır.

const FADE_TIME := 0.4

var _rect := ColorRect.new()
var _busy := false


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func fade_out() -> void:
	await _fade(1.0)


func fade_in() -> void:
	await _fade(0.0)


# fade_out → sahne değişir → fade_in; geçiş sürerken gelen ikinci istek yok sayılır
func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	await fade_out()
	get_tree().paused = false # Zamanı normale döndürmezsek yeni sahne de donuk kalır!
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	await fade_in()
	_busy = false


func _fade(alpha: float) -> void:
	# Kararmışken arkadaki butonlara tıklanmasın
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", alpha, FADE_TIME)
	await tween.finished
	if alpha == 0.0:
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
