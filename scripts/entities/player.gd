extends CharacterBody2D

class_name Player

enum State { MOVE, PUNCH, PICKUP, DEATH }

@export var MAX_SPEED: float = 200.0
@export var ACCELERATION: float = 1500.0
@export var FRICTION: float = 1200.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var axis: Vector2 = Vector2.ZERO
var state: State = State.MOVE
var facing: String = "down"

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play("idle_down")

func _physics_process(delta: float) -> void:
	if state == State.DEATH:
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
	if state == State.PUNCH or state == State.PICKUP:
		state = State.MOVE

func _play(anim_name: String) -> void:
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

# -------> End of Animation System <------- #

# -------> Attacking System <------- #
