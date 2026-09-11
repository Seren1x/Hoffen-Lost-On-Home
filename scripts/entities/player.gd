extends CharacterBody2D

## Death animation sheets (Rain Death Animation SpreadSheet Allround). Each
## sheet is a 4-frame horizontal strip; the frames are 64x64, matching the base
## sprite frames. Keyed by facing direction. Sliced at runtime via AtlasTexture
## so we reuse the already-imported sheets (no extra imported textures needed).
const DEATH_SHEETS: Dictionary = {
	"down": "res://assets/sprites/Rain Death Animation SpreadSheet Allround/deathfront.png",
	"left": "res://assets/sprites/Rain Death Animation SpreadSheet Allround/deathleftt.png",
	"right": "res://assets/sprites/Rain Death Animation SpreadSheet Allround/deathRight.png",
	"up": "res://assets/sprites/Rain Death Animation SpreadSheet Allround/deathupt.png",
}
const DEATH_FRAME_SIZE := 64
const DEATH_FRAMES := 4
const DEATH_ANIM_SPEED := 6.0

## Melee slash sprite sheets: 512x128, sliced into 4 frames of 128x128.
const MELEE_SHEETS: Dictionary = {
	"down": "res://assets/objects/melee/melee down.png",
	"left": "res://assets/objects/melee/melee left.png",
	"right": "res://assets/objects/melee/melee right.png",
	"up": "res://assets/objects/melee/melee up.png",
}
const MELEE_FRAME_SIZE := 128
const MELEE_FRAMES := 4
const MELEE_ANIM_SPEED := 8.0
const MELEE_DAMAGE: int = 15
const MELEE_RANGE: float = 40.0

@export var WALK_SPEED: float = 200.0
@export var RUN_SPEED: float = 320.0
@export var ACCELERATION: float = 1500.0
@export var FRICTION: float = 1200.0
## Manual position offsets applied to the sprite while run_* animations play,
## one per facing direction (so left/right running can be aligned separately).
## Configure these in the inspector. Defaults align the run frames to the idle/walk pose.
@export var run_offset_down: Vector2 = Vector2.ZERO
@export var run_offset_up: Vector2 = Vector2.ZERO
@export var run_offset_left: Vector2 = Vector2(2.0, 12.0)
@export var run_offset_right: Vector2 = Vector2(2.0, 12.0)

## Stamina system: running consumes stamina, which regenerates over time.
@export var max_stamina: float = 100.0
@export var stamina_drain: float = 25.0 ## Stamina lost per second while running.
@export var stamina_regen: float = 30.0 ## Stamina gained per second while not running.

var stamina: float = 100.0
## Becomes true when stamina hits 0; running stays locked until stamina is full again.
var _stamina_exhausted: bool = false

var axis: Vector2 = Vector2.ZERO
var facing: String = "down"
var is_running: bool = false

## True once the player has died. Movement, input and collision are locked and
## the matching directional death animation plays. Set by [method _on_player_died].
var _dead: bool = false

## Emitted once the player enters the death state (after the death animation starts).
## Listen here for game-over / level restart instead of coupling logic into the player.
signal player_died

@onready var anim: AnimatedSprite2D = $Body
@onready var health: Health = $Health
var _base_offset: Vector2 = Vector2.ZERO
var _hud: HUD = null
var _weapon: Weapon = null

## Melee attack state.
var _melee_attacking: bool = false

func _ready() -> void:
	# The Interactable component looks for the "player" group by default.
	add_to_group("player")
	# Tag the hurtbox so the zombie's melee attack can detect and damage us.
	$Hurtbox.add_to_group("player_hurtbox")
	_base_offset = anim.offset
	_setup_death_animations()
	_setup_melee_animations()
	_weapon = get_node_or_null("Weapon") as Weapon
	health.died.connect(_on_player_died)
	# Connect animation_finished to handle returning to idle/walk after melee.
	anim.animation_finished.connect(_on_melee_anim_finished)
	# Update the HUD reactively whenever health changes, so the bar reflects the
	# exact value the instant it hits 0 — the per-frame _sync_hud() in _process is
	# skipped once _dead is true, which previously left the bar showing the last
	# pre-death value (full health) instead of empty.
	health.health_changed.connect(_on_health_changed)


## Builds the death_<dir> SpriteFrames animations from the imported death
## sheets (each a horizontal strip of 4 frames), sliced via AtlasTexture.
## Non-looping so the sprite settles on the final frame. Idempotent.
func _setup_death_animations() -> void:
	var sf: SpriteFrames = anim.sprite_frames
	for dir: String in DEATH_SHEETS:
		var anim_name: String = "death_" + dir
		if sf.has_animation(anim_name):
			continue
		var sheet: Texture2D = load(DEATH_SHEETS[dir])
		sf.add_animation(anim_name)
		for i: int in range(DEATH_FRAMES):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(i * DEATH_FRAME_SIZE, 0, DEATH_FRAME_SIZE, DEATH_FRAME_SIZE)
			sf.add_frame(anim_name, atlas)
		sf.set_animation_loop(anim_name, false)
		sf.set_animation_speed(anim_name, DEATH_ANIM_SPEED)


## Adds melee_<dir> animations to the AnimatedSprite2D's SpriteFrames.
## Each sprite sheet (512x128) is sliced into 4 frames of 128x128 using AtlasTexture.
func _setup_melee_animations() -> void:
	var sf: SpriteFrames = anim.sprite_frames
	for dir: String in MELEE_SHEETS:
		var anim_name: String = "melee_" + dir
		if sf.has_animation(anim_name):
			continue
		var sheet: Texture2D = load(MELEE_SHEETS[dir])
		if sheet == null:
			continue
		sf.add_animation(anim_name)
		for i: int in range(MELEE_FRAMES):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(i * MELEE_FRAME_SIZE, 0, MELEE_FRAME_SIZE, MELEE_FRAME_SIZE)
			sf.add_frame(anim_name, atlas)
		sf.set_animation_loop(anim_name, false)
		sf.set_animation_speed(anim_name, MELEE_ANIM_SPEED)


## Triggers a melee slash attack when the player is unarmed.
func _try_melee_attack() -> void:
	if _melee_attacking:
		return
	if not _is_unarmed():
		return
	_melee_attacking = true
	# Play the slash animation on the AnimatedSprite2D.
	var anim_name: String = "melee_" + facing
	if anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
	# Damage enemies in range.
	var enemies = get_tree().get_nodes_in_group("enemies")
	var player_pos: Vector2 = global_position
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var dist: float = enemy.global_position.distance_to(player_pos)
			if dist <= MELEE_RANGE:
				enemy.take_damage(MELEE_DAMAGE)


func _process(delta: float) -> void:
	if _dead:
		return   # no movement/stamina/HUD while in the death state
	move(delta)
	_update_stamina(delta)
	_sync_hud()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _is_unarmed():
			_try_melee_attack()


# -------> Movement System <------- #

func get_input_axis() -> Vector2:
	axis.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	axis.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))

	return axis.normalized()


func move(delta: float) -> void:
	axis = get_input_axis()
	# Shift = run. Covers both the "run" input action and the raw Shift key
	# (the action may not be registered if the project was edited mid-editor-session).
	# Running also requires stamina and that the player is actually moving.
	var wants_run: bool = Input.is_physical_key_pressed(KEY_SHIFT) or (InputMap.has_action("run") and Input.is_action_pressed("run"))
	# Running requires stamina, movement, and not being locked out (once exhausted,
	# the player must wait for stamina to fully refill before running again).
	is_running = wants_run and not _stamina_exhausted and stamina > 0.0 and axis != Vector2.ZERO

	# Face the movement direction while moving. When stationary, keep the last
	# facing direction — the weapon's shooting arc is independent of the body.
	if axis != Vector2.ZERO:
		_update_facing(axis)

	if axis != Vector2.ZERO:
		apply_movement(ACCELERATION * axis * delta)
	else:
		apply_friction(FRICTION * delta)

	move_and_slide()
	_update_animation()


## Applies acceleration towards the walk or run target speed (Shift = running).
func apply_movement(accel: Vector2) -> void:
	var target_speed: float = RUN_SPEED if is_running else WALK_SPEED
	velocity += accel
	velocity = velocity.limit_length(target_speed)


func apply_friction(amount: float) -> void:
	if velocity.length() > amount:
		velocity -= velocity.normalized() * amount
	else:
		velocity = Vector2.ZERO


## Sets the facing direction from the movement input (up/down/left/right).
func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing = "left" if dir.x < 0 else "right"
	else:
		facing = "up" if dir.y < 0 else "down"


## Sets the facing direction from the cursor position relative to the player,
## so the body aims at the mouse (matching the weapon's cursor-tracking).
func _update_facing_from_cursor() -> void:
	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	if to_mouse.length() < 1.0:
		return
	if absf(to_mouse.x) > absf(to_mouse.y):
		facing = "left" if to_mouse.x < 0 else "right"
	else:
		facing = "up" if to_mouse.y < 0 else "down"


## Picks the animation for the current state:
## - standing still: idle_<facing>
## - moving up/down: run_<facing> (no walk sheets exist for up/down)
## - moving left/right: walk_<facing>, or run_<facing> when Shift is held.
func _update_animation() -> void:
	if _melee_attacking:
		return   # show melee animation until it finishes
	var anim_name: String
	if axis == Vector2.ZERO:
		anim_name = "idle_" + facing
	elif facing == "up" or facing == "down":
		anim_name = "run_" + facing
	else:
		anim_name = ("run_" if is_running else "walk_") + facing
	if anim.animation != anim_name:
		anim.play(anim_name)
	# Apply the per-direction run offset only during run animations; otherwise restore the base offset.
	anim.offset = _run_offset() if anim_name.begins_with("run_") else _base_offset


## Returns true when the player has no weapon equipped.
func _is_unarmed() -> bool:
	if _weapon == null:
		return true
	var def: WeaponDefinition = _weapon.get_current_definition() if _weapon.has_method("get_current_definition") else null
	return def == null


## Called when the melee animation finishes — return to idle or walk.
func _on_melee_anim_finished() -> void:
	if not _melee_attacking:
		return
	_melee_attacking = false
	var anim_name: String
	if axis == Vector2.ZERO:
		anim_name = "idle_" + facing
	elif facing == "up" or facing == "down":
		anim_name = "run_" + facing
	else:
		anim_name = ("run_" if is_running else "walk_") + facing
	if anim.animation != anim_name:
		anim.play(anim_name)
	anim.offset = _base_offset


## Returns the manual offset configured for the current facing direction.
func _run_offset() -> Vector2:
	match facing:
		"up":
			return run_offset_up
		"left":
			return run_offset_left
		"right":
			return run_offset_right
		_:
			return run_offset_down

# -------> End of Movement System <------- #

# -------> Stamina System <------- #

## Consumes stamina while running, regenerates while not running.
## Once stamina is fully depleted, running stays locked until stamina is full again.
func _update_stamina(delta: float) -> void:
	if is_running:
		stamina = maxf(0.0, stamina - stamina_drain * delta)
		if stamina <= 0.0:
			_stamina_exhausted = true
	else:
		stamina = minf(max_stamina, stamina + stamina_regen * delta)
		if _stamina_exhausted and stamina >= max_stamina:
			_stamina_exhausted = false

# -------> End of Stamina System <------- #

# -------> Health & HUD <------- #

## Damage entry point used by enemies. Routes through the Health component.
func take_damage(damage: int) -> void:
	health.take_damage(damage)


func _on_player_died(_overkill: int) -> void:
	if _dead:
		return
	_dead = true
	_play_death_animation()
	_disable_physics_and_collision()
	player_died.emit()


## Plays the death animation matching the player's last facing direction.
## Death animations are non-looping, so the sprite settles on the final frame.
func _play_death_animation() -> void:
	var death_anim: String = "death_" + facing
	if anim.sprite_frames.has_animation(death_anim):
		anim.offset = _base_offset   # death frames line up with the idle/walk pose
		anim.play(death_anim)


## Freezes the body so the dead player can't move, be damaged, or block the world.
func _disable_physics_and_collision() -> void:
	velocity = Vector2.ZERO
	$CollisionBody.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitoring", false)
	set_physics_process(false)


## Lazily finds the HUD (in the "hud" group) and caches the reference.
func _get_hud() -> HUD:
	if _hud == null:
		_hud = get_tree().get_first_node_in_group("hud") as HUD
	return _hud


## Pushes current health and stamina into the top-left HUD bars.
func _sync_hud() -> void:
	var hud: HUD = _get_hud()
	if hud == null:
		return
	hud.update_health(health.current_health, health.max_health)
	hud.update_energy(stamina, max_stamina)


## Reactive health-bar sync. Connected to Health.health_changed so the bar
## updates the instant health changes — including the hit that drops it to 0.
## (The _process-based _sync_hud() is skipped once _dead is true.)
func _on_health_changed(_current: int, _maximum: int) -> void:
	_sync_hud()

# -------> End of Health & HUD <------- #

# Others
