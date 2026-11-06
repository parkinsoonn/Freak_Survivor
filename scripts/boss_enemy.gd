extends "res://scripts/enemy_controller.gd"

# Büyük boss "Ucube Yığını" (boss_ucube.aseprite). Yerden belirir, yürür ve attack_interval'de bir sırayla saldırır:
# slam = etrafına halka mermi, beam = oyuncuya yelpaze mermi. Canı yarıya inince öfkelenir (enrage):
# hızlanır, daha sık ve daha çok mermi atar. Animasyon sürerken (belirme/saldırı/öfke) yürümez.

@export var bullet_scene: PackedScene
@export var attack_interval := 4.0
@export var ring_bullets := 12
@export var beam_bullets := 3
## Atom bombası boss'u öldürmez, canının bu oranını götürür
@export var nuke_damage_ratio := 0.25

var max_health := 0

var _busy := true
var _phase2 := false
var _attack_timer := 0.0
var _next_attack := &"attack_slam"

@onready var _sprite: AnimatedSprite2D = $Visual/Sprite


func _enter_tree() -> void:
	super()
	add_to_group("boss") # HUD can barı bulur


func _ready() -> void:
	super()
	max_health = health
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.frame_changed.connect(_on_frame_changed)
	_sprite.play(&"spawn")


func _physics_process(delta: float) -> void:
	if _busy:
		linear_velocity = Vector2.ZERO
		return
	super(delta)


func _process(delta: float) -> void:
	if _busy or is_dead:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_busy = true
		_sprite.play(_next_attack)
		_next_attack = &"attack_beam" if _next_attack == &"attack_slam" else &"attack_slam"


func take_hit() -> bool:
	var dead: bool = super()
	if dead:
		_spawn_corpse()
	else:
		_check_enrage()
	return dead


func on_nuke() -> void:
	health = maxi(health - ceili(max_health * nuke_damage_ratio), 1)
	_hit_flash()
	_check_enrage()


func _check_enrage() -> void:
	if _phase2 or health > max_health / 2.0:
		return
	_phase2 = true
	_busy = true
	speed *= 1.4
	attack_interval *= 0.6
	ring_bullets = 18
	beam_bullets = 5
	_sprite.play(&"enrage")


# Saldırının vuruş karesinde (3.) mermiler çıkar
func _on_frame_changed() -> void:
	if _sprite.frame != 3:
		return
	match _sprite.animation:
		&"attack_slam":
			var offset := randf() * TAU
			for i in ring_bullets:
				_shoot(Vector2.RIGHT.rotated(offset + TAU * i / ring_bullets), 6.0)
		&"attack_beam":
			var aim := (_player.global_position - global_position).normalized()
			for i in beam_bullets:
				_shoot(aim.rotated(deg_to_rad((i - (beam_bullets - 1) / 2.0) * 12.0)), 9.0)


func _on_animation_finished() -> void:
	_busy = false
	_attack_timer = attack_interval
	# Öfkeli fazda yürürken sargısız, kırmızı gözlü hali
	_sprite.play(&"idle_p2" if _phase2 else &"walk")


func _shoot(direction: Vector2, bullet_speed: float) -> void:
	if bullet_scene == null:
		return
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.global_position = global_position + direction * 60.0
	bullet.direction = direction
	bullet.speed = bullet_speed
	get_parent().add_child(bullet)


# Ölüm animasyonu ayrı bir sprite'ta oynar (boss node'u kill_enemy'de hemen silinir)
func _spawn_corpse() -> void:
	var corpse := AnimatedSprite2D.new()
	corpse.sprite_frames = _sprite.sprite_frames
	corpse.global_position = global_position
	corpse.rotation = _visual.rotation
	corpse.scale = _sprite.scale
	corpse.z_index = -1
	get_parent().add_child.call_deferred(corpse)
	corpse.play.call_deferred(&"death")
	corpse.animation_finished.connect(func() -> void:
		var tween := corpse.create_tween()
		tween.tween_interval(1.0)
		tween.tween_property(corpse, "modulate:a", 0.0, 0.5)
		tween.tween_callback(corpse.queue_free))
