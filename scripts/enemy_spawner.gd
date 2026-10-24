extends Node

@export var enemy_scenes: Array[PackedScene] = []

@export_group("Zorluk Ayarları")
@export var spawn_interval := 2.0
@export var min_spawn_interval := 0.4
@export var spawn_radius := 15.0

@export_group("Mini Boss")
@export var mini_boss_scene: PackedScene
@export var mini_boss_interval := 60.0

var _timer := 0.0
var _boss_timer := 0.0
var _player: Node2D
var _game_manager: Node
var _start_interval := 0.0


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_game_manager = get_tree().get_first_node_in_group("game_manager")

	# Seçilen zorluğa göre spawn sıklığını ölçekle
	_start_interval = spawn_interval * Settings.start_interval_multiplier()
	min_spawn_interval *= Settings.min_interval_multiplier()


func _process(delta: float) -> void:
	# Oyun zamanı ilerledikçe (pause hariç) spawn aralığı minimuma doğru daralır
	var t: float = clampf(_game_manager.game_time / Settings.ramp_duration(), 0.0, 1.0)
	spawn_interval = lerpf(_start_interval, min_spawn_interval, t)

	_timer += delta
	if _timer >= spawn_interval:
		_spawn_enemy()
		_timer = 0.0

	_boss_timer += delta
	if _boss_timer >= mini_boss_interval:
		_spawn(mini_boss_scene)
		_boss_timer = 0.0


func _spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		return
	_spawn(enemy_scenes.pick_random())


func _spawn(scene: PackedScene) -> void:
	if not is_instance_valid(_player) or scene == null:
		return

	var random_direction := Vector2.from_angle(randf() * TAU)
	var enemy: Node2D = scene.instantiate()
	enemy.position = _player.global_position + random_direction * spawn_radius * Settings.UNIT
	get_parent().add_child(enemy)
