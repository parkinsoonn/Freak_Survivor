extends Node2D

# Zincir yıldırım (marketten açılır): interval'de bir menzildeki en yakın düşmana çakar,
# oradan menzildeki bir sonraki en yakın düşmana sekerek toplam chains düşman vurur.

@export var spark_scene: PackedScene
@export var interval := 2.0
@export var chains := 3 # İlk hedef dahil vurulan düşman sayısı
@export var strike_range := 5.0 # birim: oyuncudan ilk hedefe ve sekmeler arası en uzak mesafe

var _unlocked := false
var _timer := 0.0
var _game_manager: Node


func _ready() -> void:
	_game_manager = get_tree().get_first_node_in_group("game_manager")


# İlk alım yıldırımı açar, sonrakiler +1 sekme
func add_lightning(amount: int) -> void:
	if _unlocked:
		chains += amount
	_unlocked = true


func decrease_interval(amount: float) -> void:
	interval = maxf(interval - amount, 0.5)


func increase_range(amount: float) -> void:
	strike_range += amount


func _process(delta: float) -> void:
	if not _unlocked:
		return
	_timer -= delta
	if _timer > 0.0:
		return

	var targets := _pick_targets()
	if targets.is_empty():
		return # Menzilde düşman yok; bir sonraki karede tekrar bakılır
	_timer = interval

	var points: Array[Vector2] = [global_position]
	for enemy in targets:
		points.append(enemy.global_position)
		_spawn_spark(enemy.global_position)
	_draw_bolt(points)
	for enemy in targets:
		_game_manager.hit_enemy(enemy)


# Oyuncudan başlayıp her adımda henüz vurulmamış en yakın düşmanı seçer
func _pick_targets() -> Array[Node2D]:
	var range_sq := pow(strike_range * Settings.UNIT, 2.0)
	var candidates := get_tree().get_nodes_in_group("enemy").filter(func(e): return not e.is_dead)
	var targets: Array[Node2D] = []
	var from := global_position
	while targets.size() < chains:
		var best: Node2D = null
		var best_sq := range_sq
		for enemy: Node2D in candidates:
			var d := from.distance_squared_to(enemy.global_position)
			if d < best_sq and not targets.has(enemy):
				best = enemy
				best_sq = d
		if best == null:
			break
		targets.append(best)
		from = best.global_position
	return targets


# Noktalar arası kırık çizgi; kısa sürede söner
func _draw_bolt(points: Array[Vector2]) -> void:
	var line := Line2D.new()
	line.top_level = true
	line.z_index = 20
	line.width = 6.0
	line.default_color = Color(0.75, 0.95, 1.0)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var normal := (b - a).orthogonal().normalized()
		line.add_point(a)
		for t in [0.25, 0.5, 0.75]:
			line.add_point(a.lerp(b, t) + normal * randf_range(-14.0, 14.0))
	line.add_point(points[-1])
	add_child(line)

	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)


func _spawn_spark(at: Vector2) -> void:
	if spark_scene == null:
		return
	var spark: Node2D = spark_scene.instantiate()
	spark.top_level = true # Oyuncuyla birlikte kaymasın
	spark.position = at
	add_child(spark)
