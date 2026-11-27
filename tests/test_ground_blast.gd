extends SceneTree

# Yer patlaması: delay dolmadan hasar vermez, dolunca yalnız yarıçap içindeki oyuncuya 1 hasar verir.
# Çalıştırma: godot --headless --path . -s tests/test_ground_blast.gd  (hata varsa exit 1)

const BLAST := preload("res://scenes/ground_blast.tscn")

var _failed := false


func _initialize() -> void:
	_run.call_deferred() # root ancak ilk karede ağaçta olur


func _run() -> void:
	var health_script := GDScript.new()
	health_script.source_code = "extends Node\nvar hits := 0\nfunc take_damage(amount: int) -> void:\n\thits += amount\n"
	health_script.reload()

	var player := Node2D.new()
	player.add_to_group("player")
	var health := Node.new()
	health.name = "Health"
	health.set_script(health_script)
	player.add_child(health)
	root.add_child(player)

	var unit: float = root.get_node("Settings").UNIT

	# İçeride: delay dolmadan hasar yok, dolunca 1 hasar
	var inside: Node2D = BLAST.instantiate()
	inside.position = Vector2(inside.radius * unit * 0.5, 0)
	root.add_child(inside)
	inside._process(inside.delay * 0.5)
	_check(health.hits == 0, "delay dolmadan hasar verdi")
	inside._process(inside.delay)
	_check(health.hits == 1, "yarıçap içindeki oyuncu hasar almadı (hits=%d)" % health.hits)

	# Dışarıda: patlasa da hasar yok
	var outside: Node2D = BLAST.instantiate()
	outside.position = Vector2(outside.radius * unit * 1.5, 0)
	root.add_child(outside)
	outside._process(outside.delay * 2.0)
	_check(health.hits == 1, "yarıçap dışındaki oyuncu hasar aldı (hits=%d)" % health.hits)

	print("test_ground_blast: ", "FAIL" if _failed else "OK")
	quit(1 if _failed else 0)


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failed = true
		push_error(message)
