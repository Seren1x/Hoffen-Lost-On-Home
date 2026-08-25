extends Node2D

signal call_weapon_reload

# references
@onready var bullet_scene = preload("res://scenes/props/Bullet.tscn")
@onready var bullet_spawn_pos: Node2D = $Texture/BulletSpawnPoint
@onready var weapon_sprite: Sprite2D = $Texture
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var reload_cooldown: Timer = $ReloadCooldown

@export var rotation_speed: float = 10.0
@export var max_ammo: int = 10

enum State { IDLE, SHOOTING, RELOADING }

var current_state: State = State.IDLE
var current_ammo: int = max_ammo

func _process(delta: float) -> void:
	$Label.text = "State: " + State.keys()[current_state] + " | Ammo: " + str(current_ammo)
	
	rotate_weapon(delta)
	
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

func rotate_weapon(delta: float) -> void:
	var global_mouse_pos = get_global_mouse_position()
	var target_angle = weapon_sprite.global_position.direction_to(global_mouse_pos).angle()
	
	# if position of mouse is on left screen, flip weapon sprite
	if global_mouse_pos.x < global_position.x:
		weapon_sprite.flip_v = true
	else:
		weapon_sprite.flip_v = false
	
	weapon_sprite.rotation = lerp_angle(weapon_sprite.rotation, target_angle, rotation_speed * delta)

func weapon_reload():
	reload_cooldown.start()
	current_ammo = max_ammo
	call_weapon_reload.emit()
	print("reload")
