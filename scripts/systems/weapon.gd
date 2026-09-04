extends Node2D
class_name Weapon

## Player weapon system.
##
## Holds a list of [WeaponDefinition]s and fires the currently equipped one.
## The core mechanic is unchanged (rotate to mouse, hold LMB to fire, R to
## reload, ammo pickups via add_ammo), but per-weapon behaviour (ammo, damage,
## fire rate, reload time, pellet spread, projectile, sprite and SFX) now comes
## from the selected [WeaponDefinition] instead of hard-coded values.
##
## Switch weapons with the 1..4 keys (or call [method switch_weapon]).

signal call_weapon_reload
## Emitted when the equipped weapon changes (index + the definition), so the HUD
## can refresh name/stats/texture.
signal weapon_changed(index: int)
## Emitted whenever current ammo changes, so the HUD can stay in sync.
signal ammo_changed(current: int, maximum: int)

# references
@onready var weapon_sprite: Sprite2D = $Texture
@onready var bullet_spawn_pos: Node2D = $Texture/BulletSpawnPoint
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var reload_cooldown: Timer = $ReloadCooldown
@onready var action_cooldown: Timer = $ActionCooldown
@onready var sfx: AudioStreamPlayer = $Sfx
@onready var action_sfx_player: AudioStreamPlayer = $ActionSfx

## The available weapon loadout. Populate in the editor or from a scene.
@export var weapon_defs: Array[WeaponDefinition] = []

@export var rotation_speed: float = 10.0

enum State { IDLE, SHOOTING, RELOADING }

var current_state: State = State.IDLE
var current_ammo: int = 0
var current_index: int = 0

## Whether the left mouse button is currently held down. Set from the actual
## input event (not per-frame polling), so a fast click is never lost and
## holding auto-fires reliably.
var _firing_held: bool = false

var _current_def: WeaponDefinition = null


func _ready() -> void:
	add_to_group("weapon")
	if weapon_defs.is_empty():
		# Fallback default so the weapon still works even if no defs are assigned.
		_current_def = WeaponDefinition.new()
		weapon_defs.append(_current_def)
	else:
		_current_def = weapon_defs[0]
	apply_definition()
	weapon_changed.emit(current_index)


func _input(event: InputEvent) -> void:
	# Track the left mouse button as an event so quick clicks and holding both
	# register reliably. _input runs for every node before the GUI consumes the
	# event, so no overlay (e.g. the full-screen fade ColorRect) can swallow the
	# click like it could with _unhandled_input.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_firing_held = event.pressed
		if event.pressed:
			# Fire immediately on the press edge; a mid-cooldown press is gated
			# inside player_shoot().
			player_shoot()


func _process(delta: float) -> void:
	$Label.text = "%s | %d/%d" % [_current_def.display_name, current_ammo, _current_def.max_ammo]

	rotate_weapon(delta)
	handle_switch_input()

	if current_state != State.RELOADING:
		if _firing_held:
			current_state = State.SHOOTING
			player_shoot()
		elif Input.is_action_just_pressed("reload"):
			current_state = State.RELOADING
			weapon_reload()
		else:
			current_state = State.IDLE
	else:
		if reload_cooldown.time_left < 0.1 and current_state == State.RELOADING:
			current_state = State.IDLE


## Fire the currently equipped weapon.
func player_shoot() -> void:
	if current_state == State.RELOADING:
		return

	# Can't fire while the action is still cycling (e.g. shotgun pump).
	if action_cooldown.time_left >= 0.1:
		return

	if attack_cooldown.time_left >= 0.1:
		return

	if current_ammo <= 0:
		_play_sfx(_current_def.empty_sfx)
		return

	# Fire one or more projectiles (shotgun = many pellets with spread).
	for i in _current_def.bullet_count:
		var bullet: Area2D = _current_def.bullet_scene.instantiate()
		var trans: Transform2D = bullet_spawn_pos.global_transform
		# Rotate each pellet around the muzzle to create the shotgun spread.
		if _current_def.bullet_count > 1:
			var spread_rad: float = deg_to_rad(_current_def.spread_degrees)
			var offset: float = randf_range(-spread_rad / 2.0, spread_rad / 2.0)
			# rotated_local keeps the muzzle position fixed and only tilts the
			# pellet's direction, so the spread fans out from the barrel instead
			# of pivoting around the world origin.
			trans = trans.rotated_local(offset)
		bullet.setup(trans, _current_def.damage, _current_def.bullet_speed, _current_def.bullet_max_range)
		get_tree().root.add_child(bullet)

	_play_sfx(_current_def.shoot_sfx)
	attack_cooldown.start(_current_def.fire_rate)
	current_ammo -= 1
	ammo_changed.emit(current_ammo, _current_def.max_ammo)

	# After the shot, the action cycles (pump/bolt/slide). This adds a delay
	# before the next shot and plays the cycling sound.
	if _current_def.action_delay > 0.0:
		action_cooldown.start(_current_def.action_delay)
	_play_action_sfx(_current_def.action_sfx)


func rotate_weapon(delta: float) -> void:
	var global_mouse_pos: Vector2 = get_global_mouse_position()
	var target_angle: float = weapon_sprite.global_position.direction_to(global_mouse_pos).angle()

	# The weapon rotates freely to the cursor (kept as before), centered on the
	# character. No facing-cone limit and no handed-side offset.

	# if position of mouse is on left screen, flip weapon sprite
	if global_mouse_pos.x < global_position.x:
		weapon_sprite.flip_v = true
	else:
		weapon_sprite.flip_v = false

	weapon_sprite.rotation = lerp_angle(weapon_sprite.rotation, target_angle, rotation_speed * delta)


func weapon_reload() -> void:
	reload_cooldown.start(_current_def.reload_time)
	_play_sfx(_current_def.reload_sfx)
	current_ammo = _current_def.max_ammo
	call_weapon_reload.emit()
	ammo_changed.emit(current_ammo, _current_def.max_ammo)


## Adds [param amount] ammo (clamped to the equipped weapon's max_ammo).
func add_ammo(amount: int) -> void:
	current_ammo = clampi(current_ammo + amount, 0, _current_def.max_ammo)
	ammo_changed.emit(current_ammo, _current_def.max_ammo)


## Switch to the weapon at [param index] (clamped). Re-applies its sprite, ammo
## capacity and resets cooldowns. Ammo is NOT shared between weapons.
func switch_weapon(index: int) -> void:
	if weapon_defs.is_empty():
		return
	current_index = clampi(index, 0, weapon_defs.size() - 1)
	_current_def = weapon_defs[current_index]
	apply_definition()
	weapon_changed.emit(current_index)
	ammo_changed.emit(current_ammo, _current_def.max_ammo)


func apply_definition() -> void:
	current_ammo = _current_def.max_ammo
	if _current_def.sprite_texture:
		weapon_sprite.texture = _current_def.sprite_texture
	weapon_sprite.scale = _current_def.sprite_scale
	# Per-weapon grip and muzzle: each gun's sprite has its own size, so its
	# hand position (offset) and barrel tip (muzzle_offset) come from the
	# definition instead of being shared across all weapons.
	weapon_sprite.offset = _current_def.sprite_offset
	bullet_spawn_pos.position = _current_def.muzzle_offset
	attack_cooldown.wait_time = _current_def.fire_rate
	reload_cooldown.wait_time = _current_def.reload_time
	# wait_time must stay > 0 (Godot errors on 0/negative), so clamp the action
	# delay to a tiny positive value when a weapon has no action cycle.
	action_cooldown.wait_time = maxf(_current_def.action_delay, 0.01)
	# Fully reset every cooldown and the state on switch so the freshly equipped
	# weapon is immediately ready to fire. Without this, switching mid-cooldown
	# or mid-reload left the new weapon locked for the OLD weapon's remaining
	# timer, causing a delay / unresponsiveness right after switching.
	attack_cooldown.stop()
	reload_cooldown.stop()
	action_cooldown.stop()
	current_state = State.IDLE


## Returns the currently equipped weapon definition (for the HUD and other UI).
func get_current_definition() -> WeaponDefinition:
	return _current_def


## Returns the total number of weapons in the loadout.
func get_weapon_count() -> int:
	return weapon_defs.size()


## Returns which cooldown is currently active for the HUD cooldown bar.
## Returns a Dictionary:
##   { "active": bool, "kind": String ("delay"|"reload"), "progress": float,
##     "total": float, "remaining": float }
## - "delay": the weapon's action cycle (e.g. shotgun pump / sniper bolt) running.
## - "reload": the reload animation window.
## progress goes 1.0 -> 0.0 as the timer drains (full at start, empty when done).
func get_cooldown_state() -> Dictionary:
	# Reload takes priority over the action delay (can't do both at once).
	if reload_cooldown.time_left > 0.0:
		return {
			"active": true,
			"kind": "reload",
			"total": reload_cooldown.wait_time,
			"remaining": reload_cooldown.time_left,
			"progress": reload_cooldown.time_left / reload_cooldown.wait_time,
		}
	if action_cooldown.time_left > 0.0:
		return {
			"active": true,
			"kind": "delay",
			"total": action_cooldown.wait_time,
			"remaining": action_cooldown.time_left,
			"progress": action_cooldown.time_left / action_cooldown.wait_time,
		}
	return { "active": false, "kind": "", "total": 0.0, "remaining": 0.0, "progress": 0.0 }


func handle_switch_input() -> void:
	# Number keys 1..4 switch weapons.
	for i in weapon_defs.size():
		if Input.is_physical_key_pressed(KEY_1 + i) and i != current_index:
			switch_weapon(i)
			return


func _play_sfx(stream: AudioStream) -> void:
	if stream == null or sfx == null:
		return
	sfx.stream = stream
	sfx.play()


func _play_action_sfx(stream: AudioStream) -> void:
	if stream == null or action_sfx_player == null:
		return
	action_sfx_player.stream = stream
	action_sfx_player.play()
