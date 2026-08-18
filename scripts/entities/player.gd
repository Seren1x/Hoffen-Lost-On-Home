extends CharacterBody2D

class_name Player

enum State { MOVE, PUNCH, PICKUP, DEATH, ATTACK }

@export var MAX_SPEED: float = 200.0
@export var ACCELERATION: float = 1500.0
@export var FRICTION: float = 1200.0

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var body_nohands_sprite: AnimatedSprite2D = $BodyNoHandsSprite
@onready var bat_sprite: AnimatedSprite2D = $BatSprite
@onready var gun_sprite: AnimatedSprite2D = $GunSprite
@onready var shotgun_sprite: AnimatedSprite2D = $ShotgunSprite

var axis: Vector2 = Vector2.ZERO
var state: State = State.MOVE
var facing: String = "down"
var weapon_type: int = 0  # 0=none, 1=bat, 2=gun, 3=shotgun
var active_body_sprite: AnimatedSprite2D

func _ready() -> void:
	active_body_sprite = body_sprite
	body_sprite.animation_finished.connect(_on_animation_finished)
	body_nohands_sprite.animation_finished.connect(_on_animation_finished)
	bat_sprite.animation_finished.connect(_on_weapon_animation_finished)
	gun_sprite.animation_finished.connect(_on_weapon_animation_finished)
	shotgun_sprite.animation_finished.connect(_on_weapon_animation_finished)
	body_sprite.play("idle_down")


func _physics_process(delta: float) -> void:
	if state == State.DEATH or state == State.ATTACK:
		return

	move(delta)
	update_animation()


# -------> Movement System <------- #

func get_input_axis() -> Vector2:
	axis.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	axis.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))

	return axis.normalized()


func move(delta: float) -> void:
	axis = get_input_axis()

	if axis == Vector2.ZERO:
		apply_friction(FRICTION * delta)
	else:
		apply_movement(ACCELERATION * axis * delta)

	move_and_slide()


func apply_movement(accel: Vector2) -> void:
	velocity += accel
	velocity = velocity.limit_length(MAX_SPEED)


func apply_friction(amount: float) -> void:
	if velocity.length() > amount:
		velocity -= velocity.normalized() * amount
	else:
		velocity = Vector2.ZERO

# -------> End of Movement System <------- #


# -------> Animation System <------- #

func update_animation() -> void:
	if state != State.MOVE:
		return

	var new_facing: String = get_facing()

	if new_facing != "":
		facing = new_facing

	if velocity.length() > 1.0:
		_play("run_" + facing)
	else:
		_play("idle_" + facing)

	_sync_weapon()


func get_facing() -> String:
	var h: int = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	var v: int = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))

	if h > 0:
		return "right"

	if h < 0:
		return "left"

	if v > 0:
		return "down"

	if v < 0:
		return "up"

	return ""


func punch() -> void:
	if state != State.MOVE:
		return

	state = State.PUNCH
	_play("punch_" + facing)


func pickup() -> void:
	if state != State.MOVE:
		return

	state = State.PICKUP
	_play("pickup_" + facing)


func die() -> void:
	state = State.DEATH
	_play("death_" + facing)


func _on_animation_finished() -> void:
	if state == State.PUNCH or state == State.PICKUP or state == State.ATTACK:
		state = State.MOVE


func _play(anim_name: String) -> void:
	if active_body_sprite.animation != anim_name:
		active_body_sprite.play(anim_name)
		


# -------> End of Animation System <------- #


# -------> Attacking System <------- #

func attack() -> void:
	if state != State.MOVE:
		return

	state = State.ATTACK

	if weapon_type == 0:
		# Unarmed: body punch animation
		_play("punch_" + facing)
		return

	# Armed: play weapon attack/shoot animation
	var prefix: String = ""
	var sprite: AnimatedSprite2D = gun_sprite
	match weapon_type:
		1: prefix = "bat"; sprite = bat_sprite
		2: prefix = "gun"; sprite = gun_sprite
		3: prefix = "shotgun"; sprite = shotgun_sprite

	var action: String = "_attack" if weapon_type == 1 else "_shoot"
	var wanim: String = prefix + "_" + _weapon_dir() + action
	sprite.play(wanim)


func _on_weapon_animation_finished() -> void:
	if state == State.ATTACK:
		state = State.MOVE
		_sync_weapon()


# -------> Weapon System <------- #

# Position offsets for each weapon sprite per direction.
# Adjust these values to align weapons with the body.
# Format: weapon_type -> {direction: Vector2(x, y)}
const WEAPON_OFFSETS: Dictionary = {
	1: {"down": Vector2(-8, 0), "up": Vector2(8, 0), "side": Vector2(-8, 0), "side_left": Vector2(8, 0)},  # Bat
	2: {"down": Vector2(-10,10 ), "up": Vector2(15, -5), "side": Vector2(10, 8), "side_left": Vector2(-10,8)},  # Gun
	3: {"down": Vector2(-10, 0), "up": Vector2(15, -5), "side": Vector2(0, 0), "side_left": Vector2(0, 0)},  # Shotgun
}

func _equip_weapon(type: int) -> void:
	weapon_type = type

	# Hide all weapon sprites first
	bat_sprite.visible = false
	gun_sprite.visible = false
	shotgun_sprite.visible = false

	var current: String = active_body_sprite.animation

	if type == 0:
		# Unequip: show body with hands, hide no-hands
		body_sprite.visible = true
		body_nohands_sprite.visible = false
		active_body_sprite = body_sprite
		if current != "":
			active_body_sprite.play(current)
	else:
		# Equip: show no-hands body + the right weapon
		body_sprite.visible = false
		body_nohands_sprite.visible = true
		active_body_sprite = body_nohands_sprite
		match type:
			1: bat_sprite.visible = true
			2: gun_sprite.visible = true
			3: shotgun_sprite.visible = true

		if current != "":
			active_body_sprite.play(current)
		_sync_weapon()


func _weapon_dir() -> String:
	match facing:
		"right":
			return "side"
		"left":
			return "side_left"
		_:
			return facing


func _sync_weapon() -> void:
	if weapon_type == 0:
		return
	var prefix: String = ""
	var sprite: AnimatedSprite2D = gun_sprite
	match weapon_type:
		1: prefix = "bat"; sprite = bat_sprite
		2: prefix = "gun"; sprite = gun_sprite
		3: prefix = "shotgun"; sprite = shotgun_sprite
	var wdir: String = _weapon_dir()
	var wanim: String = prefix + "_" + wdir + "_idle"
	if sprite.animation != wanim:
		sprite.play(wanim)
	# Apply per-direction position offset
	var offs: Dictionary = WEAPON_OFFSETS.get(weapon_type, {})
	sprite.position = offs.get(wdir, Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		attack()
		return

	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1: _equip_weapon(1)
		KEY_2: _equip_weapon(2)
		KEY_3: _equip_weapon(3)
		KEY_E: _equip_weapon(0)  # Unequip
