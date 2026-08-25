extends CharacterBody2D

@export var MAX_SPEED: float = 200.0
@export var ACCELERATION: float = 1500.0
@export var FRICTION: float = 1200.0

var axis: Vector2 = Vector2.ZERO

# references

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move(delta)

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

# Others
