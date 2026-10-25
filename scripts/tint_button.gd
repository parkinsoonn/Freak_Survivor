extends BaseButton

# Unity Button'ın Color Tint geçişi: üzerine gelince 0.96, basınca 0.78, 0.1 sn yumuşak geçiş

const NORMAL := 1.0
const HIGHLIGHTED := 0.9607843
const PRESSED := 0.78431374
const FADE := 0.1

var _tween: Tween


func _ready() -> void:
	mouse_entered.connect(_fade_to.bind(HIGHLIGHTED))
	mouse_exited.connect(_fade_to.bind(NORMAL))
	button_down.connect(_fade_to.bind(PRESSED))
	button_up.connect(_on_button_up)


func _on_button_up() -> void:
	_fade_to(HIGHLIGHTED if is_hovered() else NORMAL)


func _fade_to(value: float) -> void:
	if _tween:
		_tween.kill()
	# Pause/market/game over panelleri durmuş ağaçta çalışıyor
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "self_modulate", Color(value, value, value), FADE)
