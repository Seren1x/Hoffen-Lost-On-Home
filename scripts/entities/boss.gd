class_name Boss
extends Enemy

enum State { MOVE, TELEGRAPH, SHOOT, COOLDOWN }

@export_group("Movement")
@export var move_speed: float = 120.0
@export var acceleration: float = 500.0
@export var arrive_distance: float = 10.0

@export_group("Attack")
@export var telegraph_time: float = 0.6
@export var shots_per_burst: int = 3
@export var shot_interval: float = 0.18
@export var cooldown_time: float = 0.7
@export var projectile_scene: PackedScene = preload("res://scenes/props/BossBullet.tscn")
@export var projectile_speed: float = 260.0
@export var projectile_damage: int = 8
@export var aim_spread_degrees: float = 8.0

@export_group("Sprite")
@export var idle_sheet: Texture2D = preload("res://assets/sprites/Boss/16x32 Idle-Sheet.png")
const FRAME_SIZE: int = 32
const FRAME_COUNT: int = 4
const ROW_DOWN: int = 0
const ROW_DOWN_SIDE: int = 1
const ROW_SIDE: int = 2
const ROW_UP_SIDE: int = 3
const ROW_UP: int = 4

const IDLE_ANIM_NAMES: Array[String] = ["idle_down", "idle_down_side", "idle_side", "idle_up_side", "idle_up"]
const ATTACK_ANIM_NAMES: Array[String] = ["attack_down", "attack_down_side", "attack_side", "attack_up_side", "attack_up"]

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var muzzle: Marker2D = $Muzzle
@onready var waypoints_root: Node2D = get_node_or_null("Waypoints")

var state: State = State.MOVE
var waypoint_positions: Array[Vector2] = []
var _last_waypoint_position: Vector2 = Vector2.ZERO
var _facing_dir: Vector2 = Vector2.DOWN
var _target_position: Vector2 = Vector2.ZERO

func _ready_enemy() -> void:
	flash_sprite = sprite
	max_health = 400
	_build_idle_animations()
	_gather_waypoints()
	if not waypoint_positions.is_empty():
		_target_position = waypoint_positions[0]
	_run_state_machine()

func _physics_process(delta: float) -> void:
	if dead:
		return
	if state == State.MOVE:
		var to_target := _target_position - global_position
		if to_target.length() > arrive_distance:
			velocity = to_target.normalized() * move_speed
			_play_facing_animation(to_target.normalized())
		else:
			velocity = Vector2.ZERO
		move_and_slide()
	else:
		var decel := acceleration * delta
		if velocity.length() > decel:
			velocity -= velocity.normalized() * decel
		else:
			velocity = Vector2.ZERO
		if state == State.TELEGRAPH or state == State.SHOOT:
			var player := _get_player()
			if player != null:
				_play_facing_animation((player.global_position - global_position).normalized())
		move_and_slide()

func _run_state_machine() -> void:
	while not dead:
		await _state_move()
		if dead: return
		await _state_telegraph()
		if dead: return
		await _state_shoot()
		if dead: return
		await _state_cooldown()

func _state_move() -> void:
	state = State.MOVE
	_target_position = _pick_next_point()
	while not dead:
		if global_position.distance_to(_target_position) < arrive_distance:
			break
		await get_tree().process_frame

func _state_telegraph() -> void:
	state = State.TELEGRAPH
	velocity = Vector2.ZERO
	var player := _get_player()
	if player != null:
		_play_facing_animation((player.global_position - global_position).normalized())
	await get_tree().create_timer(telegraph_time).timeout

func _state_shoot() -> void:
	state = State.SHOOT
	velocity = Vector2.ZERO
	for i in shots_per_burst:
		if dead: return
		_fire_projectile()
		if i < shots_per_burst - 1:
			await get_tree().create_timer(shot_interval).timeout

func _state_cooldown() -> void:
	state = State.COOLDOWN
	await get_tree().create_timer(cooldown_time).timeout

func _pick_next_point() -> Vector2:
	if waypoint_positions.is_empty():
		return global_position
	var candidates: Array[Vector2] = []
	for wp in waypoint_positions:
		if wp != _last_waypoint_position:
			candidates.append(wp)
	if candidates.is_empty():
		candidates = waypoint_positions
	var chosen: Vector2 = candidates.pick_random()
	_last_waypoint_position = chosen
	return chosen

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _fire_projectile() -> void:
	var player := _get_player()
	if player == null:
		return
	var to_player := player.global_position - muzzle.global_position
	if to_player.length() < 1.0:
		return
	var base_angle := to_player.angle()
	var spread_rad := deg_to_rad(aim_spread_degrees)
	var offset := randf_range(-spread_rad, spread_rad)
	var final_angle := base_angle + offset
	var cos_a := cos(final_angle)
	var sin_a := sin(final_angle)
	var trans := Transform2D()
	trans.x = Vector2(cos_a, sin_a)
	trans.y = Vector2(-sin_a, cos_a)
	trans.origin = muzzle.global_position
	var bullet := projectile_scene.instantiate() as Area2D
	if bullet == null:
		return
	bullet.setup(trans, projectile_damage, projectile_speed)
	get_tree().root.add_child(bullet)

func _build_idle_animations() -> void:
	# SpriteFrames now loaded from boss_idle_sprites.tres resource
	sprite.visible = true
	sprite.play("idle_down")

func _play_facing_animation(dir: Vector2) -> void:
	var d := dir.normalized()
	var angle := d.angle()
	var a := fmod(angle + TAU, TAU)
	var row: int
	if a < PI / 8.0 or a >= 15.0 * PI / 8.0:
		row = ROW_SIDE
	elif a < 3.0 * PI / 8.0:
		row = ROW_DOWN_SIDE
	elif a < 5.0 * PI / 8.0:
		row = ROW_DOWN
	elif a < 7.0 * PI / 8.0:
		row = ROW_DOWN_SIDE
	elif a < 9.0 * PI / 8.0:
		row = ROW_SIDE
	elif a < 11.0 * PI / 8.0:
		row = ROW_UP_SIDE
	elif a < 13.0 * PI / 8.0:
		row = ROW_UP
	else:
		row = ROW_UP_SIDE
	sprite.flip_h = d.x < -0.1
	var anim_names: Array[String] = IDLE_ANIM_NAMES if state != State.SHOOT else ATTACK_ANIM_NAMES
	var anim_name: String = anim_names[row]
	if sprite.animation != anim_name:
		sprite.play(anim_name)
	_facing_dir = d

func _gather_waypoints() -> void:
	if waypoints_root == null:
		return
	for child in waypoints_root.get_children():
		var marker := child as Marker2D
		if marker != null:
			waypoint_positions.append(marker.global_position)

func _die() -> void:
	velocity = Vector2.ZERO
	if _flash_tween:
		_flash_tween.kill()
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void: queue_free())
