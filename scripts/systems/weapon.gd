extends Node2D

signal call_weapon_reload

# references
@onready var bullet_scene = preload("res://scenes/props/Bullet.tscn")
@onready var bullet_spawn_pos: Node2D = $Texture/BulletSpawnPoint
@onready var weapon_sprite: Sprite2D = $Texture
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var reload_cooldown: Timer = $ReloadCooldown
@onready var action_cooldown: Timer = $ActionCooldown
@onready var sfx: AudioStreamPlayer = $Sfx
@onready var action_sfx_player: AudioStreamPlayer = $ActionSfx
@onready var top_guide_line: Line2D = $TopGuideLine
@onready var bottom_guide_line: Line2D = $BottomGuideLine

## The available weapon loadout. Populate in the editor or from a scene.
@export var weapon_defs: Array[WeaponDefinition] = []

@export var rotation_speed: float = 10.0
@export var max_ammo: int = 10

enum State { IDLE, SHOOTING, RELOADING }

var current_state: State = State.IDLE
var current_ammo: int = max_ammo

func _process(delta: float) -> void:
	$Label.text = "State: " + State.keys()[current_state] + " | Ammo: " + str(current_ammo)
	
	rotate_weapon(delta)
	_update_guide_lines()
	handle_switch_input()

	if current_state != State.RELOADING:
		if Input.is_action_pressed("left_click"):
			current_state = State.SHOOTING
			player_shoot()
		elif Input.is_action_just_pressed("reload"):
			current_state = State.RELOADING
			weapon_reload()
		else:
			current_state = State.IDLE
	else:
		if reload_cooldown.time_left < 0.1 and current_state == State.RELOADING:
			print("Console Log: ")
			current_state = State.IDLE

func player_shoot() -> void:
	if current_state == State.RELOADING:
		return
	
	if attack_cooldown.time_left < 0.1 and current_ammo > 0:
		var bullet = bullet_scene.instantiate()
		bullet.setup(bullet_spawn_pos.global_transform)
		get_tree().root.add_child(bullet)
		
		attack_cooldown.start()
		current_ammo -= 1
		print("Current ammo: " + str(current_ammo))

## Max elevation angle (radians) the weapon can tilt up/down from the facing axis.
const SHOOTING_ARC_HALF: float = PI / 4.0  # 45 degrees
## Pixel length of the guide lines drawn at the arc boundaries.
const GUIDE_LINE_LENGTH: float = 250.0

func rotate_weapon(delta: float) -> void:
	var global_mouse_pos: Vector2 = get_global_mouse_position()

	# The bullet travels along the sprite's local X axis, so sprite rotation
	# directly equals the bullet's world-space direction.
	var raw_angle: float = weapon_sprite.global_position.direction_to(global_mouse_pos).angle()

	# Clamp the target angle within +/-45 degrees of the player's facing direction.
	var center_angle: float = _facing_center_angle()
	var diff: float = angle_difference(center_angle, raw_angle)
	diff = clampf(diff, -SHOOTING_ARC_HALF, SHOOTING_ARC_HALF)
	var target_angle: float = center_angle + diff

	# Flip the sprite vertically when facing left so the gun barrel points the
	# correct way without being upside-down. Based on facing, not mouse position.
	var player_facing: String = _get_player_facing()
	weapon_sprite.flip_v = (player_facing == "left")

	weapon_sprite.rotation = lerp_angle(weapon_sprite.rotation, target_angle, rotation_speed * delta)


## Returns the player's current facing direction ("left", "right", "up", "down").
func _get_player_facing() -> String:
	var player: Node2D = get_parent()
	return player.get(&"facing") if player else "down"


## Returns the center angle (radians) of the shooting arc based on the player's
## current facing direction. The barrel points RIGHT in the texture, so the
## sprite rotation directly equals the barrel's world-space angle.
func _facing_center_angle() -> float:
	match _get_player_facing():
		"right":
			return 0.0
		"left":
			return PI
		"up":
			return -PI / 2.0
		_:
			return PI / 2.0  # "down" or fallback


## Redraws the guide lines showing the min/max elevation of the shooting arc.
func _update_guide_lines() -> void:
	var center_angle: float = _facing_center_angle()
	var top_angle: float = center_angle - SHOOTING_ARC_HALF
	var bottom_angle: float = center_angle + SHOOTING_ARC_HALF

	var end_top: Vector2 = Vector2.RIGHT.rotated(top_angle) * GUIDE_LINE_LENGTH
	var end_bottom: Vector2 = Vector2.RIGHT.rotated(bottom_angle) * GUIDE_LINE_LENGTH

	top_guide_line.points = PackedVector2Array([Vector2.ZERO, end_top])
	bottom_guide_line.points = PackedVector2Array([Vector2.ZERO, end_bottom])


func weapon_reload() -> void:
	reload_cooldown.start(_current_def.reload_time)
	_play_sfx(_current_def.reload_sfx)
	current_ammo = _current_def.max_ammo
	call_weapon_reload.emit()
	print("reload")


## Adds [param amount] ammo (clamped to max_ammo). Used by ammo pickups.
func add_ammo(amount: int) -> void:
	current_ammo = clampi(current_ammo + amount, 0, max_ammo)
	print("Current ammo: " + str(current_ammo))
