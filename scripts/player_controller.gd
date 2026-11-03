extends RigidBody2D

@export_group("Hareket Ayarları")
@export var move_speed := 5.0

## Bu yarıçapa (birim) giren altın oyuncuya uçar
@export var pickup_radius := 2.0

@export_group("Ateş Etme Ayarları")
@export var fire_rate := 0.5

@export_group("Çoklu Atış")
@export var bullet_count := 1
@export var spread_angle := 10.0 # Mermiler arası açı
@export var max_spread_angle := 60.0 # Yelpazenin toplam genişliği bunu geçmez

@export var bullet_speed := 20.0 # birim/sn
@export var bullet_size := 1.0 # Sprite + collider ölçeği

@export var bullet_scene: PackedScene
@export var shoot_sound: AudioStream
@export_range(0.0, 1.0) var shoot_volume := 0.5

@export_group("Dash Ayarları")
@export var dash_speed := 18.0
@export var dash_duration := 0.2
@export var dash_cooldown := 1.5

@export_group("Dash UI Ayarları")
@export var dash_icon: TextureRect
@export var dash_cooldown_text: Label

@export_group("Atom Bombası")
@export var nuke_cooldown := 60.0
@export var nuke_icon: TextureRect
@export var nuke_cooldown_text: Label
@export var nuke_flash: ColorRect # Tam ekran beyaz flaş
@export var nuke_effect: PackedScene
@export var nuke_sound: AudioStream

@export_group("Bariyer")
@export var barrier_duration := 2.0
@export var barrier_cooldown := 15.0
@export var barrier_icon: TextureRect
@export var barrier_cooldown_text: Label

var _movement := Vector2.ZERO
var _next_fire_time := 0.0
var _clock := 0.0
# Oyun durduğunda (menü butonuna tıklarken) basılı tutulan tık, bırakılana kadar ateş etmesin
var _fire_locked := false

var _is_dashing := false
var _dash_time := 0.0
var _dash_direction := Vector2.ZERO
var _dash_cooldown_timer := 0.0
var _nuke_cooldown_timer := 0.0
var _nuke_flash_time := -1.0
var _barrier_cooldown_timer := 0.0
var _barrier_time := -1.0 # Kalkan açıkken geçen süre; -1 = kapalı

var _game_manager: Node
var _camera: Node

@onready var _visual: Node2D = $Visual
@onready var _shape: CollisionShape2D = $Shape
@onready var _fire_point: Node2D = $Visual/FirePoint
@onready var _health: Node = $Health
@onready var _dash_trail: Line2D = $DashTrail
@onready var _shield: AnimatedSprite2D = $Shield
@onready var _shield_scale: Vector2 = _shield.scale
@onready var _audio: AudioStreamPlayer = $ShootSound
@onready var _pickup_shape: CollisionShape2D = $PickupArea/Shape


func _enter_tree() -> void:
	add_to_group("player")


func _ready() -> void:
	gravity_scale = 0.0
	lock_rotation = true

	if dash_cooldown_text: dash_cooldown_text.text = ""
	if nuke_cooldown_text: nuke_cooldown_text.text = ""
	if barrier_cooldown_text: barrier_cooldown_text.text = ""
	_dash_trail.emitting = false
	_audio.stream = shoot_sound
	_audio.volume_db = linear_to_db(shoot_volume)

	_pickup_shape.shape.radius = pickup_radius * Settings.UNIT
	$PickupArea.area_entered.connect(_on_pickup_area_entered)

	_game_manager = get_tree().get_first_node_in_group("game_manager")
	_camera = get_tree().get_first_node_in_group("camera")


func _notification(what: int) -> void:
	# Pause, market ve Game Over ekranlarından dönünce basılı tık ateş etmesin
	if what == NOTIFICATION_UNPAUSED:
		_fire_locked = true


func _process(delta: float) -> void:
	_clock += delta

	_movement = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var fire_held := Input.is_action_pressed("fire")
	if not fire_held:
		_fire_locked = false

	if fire_held and not _fire_locked and _clock >= _next_fire_time:
		_shoot()
		_next_fire_time = _clock + fire_rate

	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta
		_update_cooldown_ui(_dash_cooldown_timer, dash_cooldown, dash_icon, dash_cooldown_text)

	if Input.is_action_just_pressed("dash") and not _is_dashing and _dash_cooldown_timer <= 0.0:
		_start_dash()

	if _nuke_cooldown_timer > 0.0:
		_nuke_cooldown_timer -= delta
		_update_cooldown_ui(_nuke_cooldown_timer, nuke_cooldown, nuke_icon, nuke_cooldown_text)

	if Input.is_action_just_pressed("nuke") and _nuke_cooldown_timer <= 0.0:
		_perform_nuke()

	if _nuke_flash_time >= 0.0 and nuke_flash:
		_nuke_flash_time += delta
		nuke_flash.color.a = 1.0 - _nuke_flash_time / 0.6
		if _nuke_flash_time >= 0.6:
			nuke_flash.visible = false
			_nuke_flash_time = -1.0

	if _barrier_cooldown_timer > 0.0:
		_barrier_cooldown_timer -= delta
		_update_cooldown_ui(_barrier_cooldown_timer, barrier_cooldown, barrier_icon, barrier_cooldown_text)

	if Input.is_action_just_pressed("barrier") and _barrier_cooldown_timer <= 0.0 and _barrier_time < 0.0:
		_start_barrier()

	if _barrier_time >= 0.0:
		_barrier_time += delta
		_update_shield()
		if _barrier_time >= barrier_duration:
			_end_barrier()


func _physics_process(delta: float) -> void:
	if _is_dashing:
		# Hız dash boyunca yüksek kalır, sadece sonda yürüme hızına yumuşakça iner (ani durma yok)
		var eased := pow(_dash_time / dash_duration, 3.0)
		linear_velocity = _dash_direction * lerpf(dash_speed, move_speed, eased) * Settings.UNIT
		_dash_time += delta
		if _dash_time >= dash_duration:
			_end_dash()
	else:
		linear_velocity = _movement.normalized() * move_speed * Settings.UNIT

	# Görselin alt kenarı (yüzü) fareye baksın
	var look_dir := get_global_mouse_position() - global_position
	var angle := look_dir.angle() - PI / 2.0
	_visual.rotation = angle
	_shape.rotation = angle


func _start_dash() -> void:
	_is_dashing = true
	_dash_time = 0.0
	_dash_cooldown_timer = dash_cooldown
	_health.is_invincible = true

	_dash_direction = _movement.normalized()
	if _dash_direction == Vector2.ZERO:
		# Unity'deki transform.up: görselin üst kenarı, yani fareden uzağa
		_dash_direction = -_aim_direction()

	_dash_trail.emitting = true


func _end_dash() -> void:
	_health.is_invincible = _barrier_time >= 0.0 # Bariyer açıksa koruma sürsün
	_dash_trail.emitting = false
	_is_dashing = false


func _perform_nuke() -> void:
	_nuke_cooldown_timer = nuke_cooldown

	if _game_manager:
		for enemy in get_tree().get_nodes_in_group("enemy"):
			_game_manager.kill_enemy(enemy, false)

	# Tek tek ses/sarsıntı yerine tek büyük patlama
	if _camera: _camera.trigger_shake(0.5, 0.6)
	if nuke_sound and _game_manager: _game_manager.play_sound(nuke_sound, 0.1)
	if nuke_effect:
		var fx: Node2D = nuke_effect.instantiate()
		fx.global_position = global_position
		fx.scale *= 4.0
		get_parent().add_child(fx)

	if nuke_flash == null:
		return
	nuke_flash.visible = true
	nuke_flash.color.a = 1.0
	_nuke_flash_time = 0.0


# Açılışta kalkan sıfırdan büyüyüp hafif taşar ve beyaz parlar
func _start_barrier() -> void:
	_barrier_time = 0.0
	_barrier_cooldown_timer = barrier_cooldown
	_health.is_invincible = true
	if _camera: _camera.trigger_shake(0.15, 0.2)

	_shield.visible = true
	_shield.play()
	_shield.scale = Vector2.ZERO
	_shield.modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween := _shield.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_shield, "scale", _shield_scale, 0.25)
	tween.parallel().tween_property(_shield, "modulate", Color(1.0, 1.0, 1.0, 0.85), 0.3)


# Aktifken nabız gibi atar; son 0.5 sn yanıp sönerek bittiğini haber verir
func _update_shield() -> void:
	if _barrier_time < 0.3:
		return # Açılış tween'i sürüyor
	_shield.scale = _shield_scale * (1.0 + 0.04 * sin(_barrier_time * 12.0))
	var left := barrier_duration - _barrier_time
	_shield.modulate.a = (0.25 if int(left * 12.0) % 2 == 0 else 0.85) if left < 0.5 else 0.85


# Kapanışta kalkan genişleyip saydamlaşarak kaybolur
func _end_barrier() -> void:
	_barrier_time = -1.0
	_health.is_invincible = _is_dashing
	var tween := _shield.create_tween()
	tween.tween_property(_shield, "scale", _shield_scale * 1.4, 0.2)
	tween.parallel().tween_property(_shield, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void:
		_shield.stop()
		_shield.visible = false)


func _on_pickup_area_entered(area: Area2D) -> void:
	if area.is_in_group("gold"):
		area.attract(self)


func increase_speed(amount: float) -> void:
	move_speed += amount


func increase_pickup_radius(amount: float) -> void:
	pickup_radius += amount
	_pickup_shape.shape.radius = pickup_radius * Settings.UNIT


func add_bullet(amount: int) -> void:
	bullet_count += amount


func increase_fire_rate(amount: float) -> void:
	fire_rate = maxf(fire_rate - amount, 0.1)


func increase_bullet_speed(amount: float) -> void:
	bullet_speed += amount


func increase_bullet_size(amount: float) -> void:
	bullet_size += amount


func decrease_dash_cooldown(amount: float) -> void:
	dash_cooldown = maxf(dash_cooldown - amount, 0.3)


func set_dash_ui_visibility(shown: bool) -> void:
	for control in [dash_icon, dash_cooldown_text, nuke_icon, nuke_cooldown_text, barrier_icon, barrier_cooldown_text]:
		if control: control.visible = shown


# İkonun üstünde saat yönünde açılan karartma + ortada kalan süre; hazır olunca kısa bir "pop"
func _update_cooldown_ui(timer: float, duration: float, icon: TextureRect, text: Label) -> void:
	var on_cooldown := timer > 0.0
	if text:
		text.text = ("%.1f" % timer) if on_cooldown else ""
	if icon == null:
		return

	icon.get_node("Cooldown").value = timer / duration * 100.0 if on_cooldown else 0.0
	if not on_cooldown:
		icon.pivot_offset = icon.size / 2.0
		icon.scale = Vector2(1.3, 1.3)
		icon.create_tween().tween_property(icon, "scale", Vector2.ONE, 0.2)


# Görselin alt kenarının (yüzünün) baktığı yön
func _aim_direction() -> Vector2:
	return Vector2.DOWN.rotated(_visual.rotation)


func _shoot() -> void:
	if bullet_scene == null:
		return

	# Mermi sayısı arttıkça aralarındaki açı daralır, yelpaze max_spread_angle'ı geçmez
	var step := minf(spread_angle, max_spread_angle / (bullet_count - 1)) if bullet_count > 1 else 0.0
	for i in bullet_count:
		var offset := (i - (bullet_count - 1) / 2.0) * step
		var bullet: Node2D = bullet_scene.instantiate()
		bullet.global_position = _fire_point.global_position
		bullet.direction = _aim_direction().rotated(deg_to_rad(offset))
		bullet.speed = bullet_speed
		bullet.scale = Vector2.ONE * bullet_size
		bullet.rotation = bullet.direction.angle() + PI / 2.0
		get_parent().add_child(bullet)

	if shoot_sound:
		_audio.play()
