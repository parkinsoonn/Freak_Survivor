extends "res://scripts/enemy_controller.gd"

# Büyük boss "Ucube Yığını" (boss_ucube.aseprite). Yerden belirir, yürür ve attack_interval'de bir ATTACKS sırasıyla saldırır:
# slam = etrafına halka mermi, burst = oyuncuya seri hızlı mermi, beam = oyuncuya yelpaze mermi,
# spiral = dönen mermi yağmuru, blasts = oyuncunun ayağına art arda yer patlaması.
# Canı yarıya inince öfkelenir (enrage): hızlanır, daha sık ve daha çok saldırır.
# Animasyon ya da seri saldırı sürerken (belirme/saldırı/öfke) yürümez.

const ATTACKS: Array[StringName] = [&"slam", &"burst", &"beam", &"spiral", &"blasts"]
const ATTACK_ANIMS := {
	&"slam": &"attack_slam", &"burst": &"attack_beam", &"beam": &"attack_beam",
	&"spiral": &"attack_slam", &"blasts": &"attack_slam",
}

@export var bullet_scene: PackedScene
@export var blast_scene: PackedScene
@export var attack_interval := 4.0
@export var ring_bullets := 12
@export var beam_bullets := 3
@export_group("Seri saldırılar")
@export var burst_bullets := 7
@export var burst_step := 0.08
@export var spiral_arms := 2
@export var spiral_duration := 2.4
@export var spiral_step := 0.07
@export var blast_count := 4
@export var blast_step := 0.25
@export_group("")
## Atom bombası boss'u öldürmez, canının bu oranını götürür
@export var nuke_damage_ratio := 0.25

var max_health := 0

var _busy := true
var _phase2 := false
var _attack_timer := 0.0
var _attack_index := 0
var _attack := &""
# Seri saldırı: kalan atış sayısı ve sonrakine kalan süre (pause'da _process durduğu için seri de durur)
var _volley_left := 0
var _volley_wait := 0.0
var _spiral_angle := 0.0

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
	if is_dead:
		return
	if _volley_left > 0:
		_volley_wait -= delta
		if _volley_wait <= 0.0:
			_volley_step()
		return
	if _busy:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_busy = true
		_attack = ATTACKS[_attack_index]
		_attack_index = (_attack_index + 1) % ATTACKS.size()
		_sprite.play(ATTACK_ANIMS[_attack])


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
	burst_bullets = 11
	spiral_arms = 3
	blast_count = 6
	_sprite.play(&"enrage")


# Saldırının vuruş karesinde (3.) mermiler çıkar ya da seri saldırı başlar
func _on_frame_changed() -> void:
	if _sprite.frame != 3 or _sprite.animation != ATTACK_ANIMS.get(_attack):
		return
	match _attack:
		&"slam":
			var offset := randf() * TAU
			for i in ring_bullets:
				_shoot(Vector2.RIGHT.rotated(offset + TAU * i / ring_bullets), 6.0)
		&"beam":
			var aim := (_player.global_position - global_position).normalized()
			for i in beam_bullets:
				_shoot(aim.rotated(deg_to_rad((i - (beam_bullets - 1) / 2.0) * 12.0)), 9.0)
		&"burst":
			_volley_left = burst_bullets
		&"spiral":
			_volley_left = int(spiral_duration / spiral_step)
			_spiral_angle = randf() * TAU
		&"blasts":
			_volley_left = blast_count
	_volley_wait = 0.0


func _volley_step() -> void:
	match _attack:
		&"burst": # Her mermide yeniden nişan alır
			_shoot((_player.global_position - global_position).normalized(), 12.0)
			_volley_wait = burst_step
		&"spiral":
			for arm in spiral_arms:
				_shoot(Vector2.RIGHT.rotated(_spiral_angle + TAU * arm / spiral_arms), 7.0)
			_spiral_angle += deg_to_rad(14.0)
			_volley_wait = spiral_step
		&"blasts":
			_blast(_player.global_position)
			_volley_wait = blast_step
	_volley_left -= 1
	# Animasyon seriden önce bittiyse boss beklemedeydi; seri bitince yürümeye döner
	if _volley_left == 0 and _sprite.animation in [&"idle", &"idle_p2"]:
		_finish_attack()


func _on_animation_finished() -> void:
	if _volley_left > 0:
		_sprite.play(&"idle_p2" if _phase2 else &"idle")
		return
	_finish_attack()


func _finish_attack() -> void:
	_busy = false
	_attack_timer = attack_interval
	# Öfkeli fazda yürürken sargısız, kırmızı gözlü hali
	_sprite.play(&"idle_p2" if _phase2 else &"walk")


func _blast(at: Vector2) -> void:
	if blast_scene == null:
		return
	var blast: Node2D = blast_scene.instantiate()
	blast.global_position = at
	get_parent().add_child(blast)


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
