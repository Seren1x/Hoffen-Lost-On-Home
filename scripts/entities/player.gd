extends CharacterBody2D

@export var MAX_SPEED: float = 200.0
@export var ACCELERATION: float = 1500.0
@export var FRICTION: float = 1200.0

@export var rotation_speed: float = 10.0

var axis: Vector2 = Vector2.ZERO

# references
@onready var bullet_scene = preload("res://scenes/props/Bullet.tscn")
@onready var bullet_spawn_pos: Node2D = $Weapon/BulletSpawnPoint
@onready var weapon_sprite: Sprite2D = $Weapon
@onready var attack_cooldown: Timer = $AttackCooldown

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move(delta)
	rotate_weapon(delta)
	
	if Input.is_action_pressed("left_click"):
		player_shoot()


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

# -------> Shoot System <------- #
func player_shoot():
	if attack_cooldown.time_left < 0.1:
		var bullet = bullet_scene.instantiate()
		bullet.setup(bullet_spawn_pos.global_transform)
		get_tree().root.add_child(bullet)
		attack_cooldown.start()

# -------> End of Shoot System <------- #

# Others
func rotate_weapon(delta):
	var global_mouse_pos = get_global_mouse_position()
	var target_angle = weapon_sprite.global_position.direction_to(global_mouse_pos).angle()
	
	# if position of mouse is on left screen, flip weapon sprite
	if global_mouse_pos.x < global_position.x:
		weapon_sprite.flip_v = true
	else:
		weapon_sprite.flip_v = false
	
	weapon_sprite.rotation = lerp_angle(weapon_sprite.rotation, target_angle, rotation_speed * delta)
