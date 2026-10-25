extends Node

# WaveManager FIGHT başında start_wave ile açar, wave bitince stop ile kapatır

@export var enemy_scenes: Array[PackedScene] = []

@export_group("Zorluk Ayarları")
@export var spawn_interval := 2.0
@export var min_spawn_interval := 0.4
@export var spawn_radius := 15.0

@export_group("Mini Boss")
@export var mini_boss_scene: PackedScene
## Her kaçıncı wave'in ortasında bir kez golem çıkar
@export var mini_boss_every := 5

var _timer := 0.0
var _wave_time := 0.0
var _boss_time := -1.0 # Bu wave'de golemin çıkacağı an; -1 = yok
var _player: Node2D
var _start_interval := 0.0


func _ready() -> void:
	set_process(false)
	_player = get_tree().get_first_node_in_group("player")

	# Seçilen zorluğa göre spawn sıklığını ölçekle
	_start_interval = spawn_interval * Settings.start_interval_multiplier()
	min_spawn_interval *= Settings.min_interval_multiplier()


func start_wave(wave: int, duration: float) -> void:
	# Wave numarası arttıkça spawn aralığı ramp_waves. wave'de minimuma iner
	var t := clampf((wave - 1) / (Settings.ramp_waves() - 1.0), 0.0, 1.0)
	spawn_interval = lerpf(_start_interval, min_spawn_interval, t)

	_timer = 0.0
	_wave_time = 0.0
	_boss_time = duration / 2.0 if wave % mini_boss_every == 0 else -1.0
	set_process(true)


func stop() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= spawn_interval:
		_spawn_enemy()
		_timer = 0.0

	_wave_time += delta
	if _boss_time >= 0.0 and _wave_time >= _boss_time:
		_spawn(mini_boss_scene)
		_boss_time = -1.0


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
