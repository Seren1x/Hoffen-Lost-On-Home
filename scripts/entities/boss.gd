class_name Boss
extends Enemy

## Boss enemy template.
##
## Built on the shared Enemy base (see enemy.gd) the same way zombie_axe.gd is -
## Health / Hurtbox / hit-flash / death signal are already wired for you.
## Fill in the TODOs below to get:
##
##   MOVE (go to a random waypoint) -> TELEGRAPH (aim + warn) -> SHOOT (aimed
##   burst) -> COOLDOWN -> back to MOVE ...
##
## Design constraints to keep in mind while filling these in:
## - Randomness belongs in WHICH waypoint is picked next, not in the movement
##   itself - movement should be a smooth, deliberate steer toward a fixed point.
## - The boss should only ever fire during SHOOT, never while moving, so
##   approaching it during MOVE/COOLDOWN is always safe.
## - TELEGRAPH must be long enough that an alert player can react and move.
## - Projectiles should NOT home; aim once (at fire time) and travel straight,
##   with a little random spread, so a moving player can dodge.

enum State { MOVE, TELEGRAPH, SHOOT, COOLDOWN }

@export_group("Movement")
@export var move_speed: float = 90.0
@export var acceleration: float = 500.0
## How close (px) counts as "arrived" at a waypoint.
@export var arrive_distance: float = 10.0

@export_group("Attack")
## Seconds the boss winds up before firing - the player's warning window.
@export var telegraph_time: float = 0.6
@export var shots_per_burst: int = 3
@export var shot_interval: float = 0.18
@export var cooldown_time: float = 0.7
@export var projectile_scene: PackedScene = preload("res://scenes/props/BossBullet.tscn")
@export var projectile_speed: float = 260.0
@export var projectile_damage: int = 8
## Random angle (deg) added per shot so a burst is a loose fan, not a laser.
@export var aim_spread_degrees: float = 8.0

@export_group("Sprite")
@export var idle_sheet: Texture2D = preload("res://assets/sprites/Boss/16x32 Idle-Sheet.png")
## Uploaded sheet is 128x160 = 4 frames x 5 rows of 32x32.
## Rows top -> bottom: down, down-side, side, up-side, up.
const FRAME_SIZE: int = 32
const FRAME_COUNT: int = 4
const ROW_DOWN: int = 0
const ROW_DOWN_SIDE: int = 1
const ROW_SIDE: int = 2
const ROW_UP_SIDE: int = 3
const ROW_UP: int = 4

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var muzzle: Marker2D = $Muzzle
@onready var waypoints_root: Node2D = get_node_or_null("Waypoints")

var state: State = State.MOVE
var waypoints: Array[Marker2D] = []
var _last_waypoint: Marker2D = null
var _facing_dir: Vector2 = Vector2.DOWN


# ------------------------------------------------------------------ #
# Setup
# ------------------------------------------------------------------ #

## Enemy._ready() calls this hook before wiring Health/Hurtbox (see enemy.gd),
## same as zombie_axe.gd's _ready_enemy().
func _ready_enemy() -> void:
	flash_sprite = sprite
	# TODO: build the idle AnimatedSprite2D animations from idle_sheet.
	# Slice FRAME_COUNT x FRAME_SIZE regions per row into looping animations,
	# same technique as player.gd's _setup_death_animations() (AtlasTexture
	# slicing at runtime, no manual .tres needed).
	# _build_idle_animations()

	# TODO: collect Marker2D children under `waypoints_root` into `waypoints`.
	# _gather_waypoints()

	# TODO: kick off the state machine loop (see _run_state_machine below).
	pass


func _physics_process(delta: float) -> void:
	if dead:
		return
	# TODO: drive movement here when state == State.MOVE (steer velocity
	# toward the current target with move_toward + move_and_slide, like
	# zombie_axe.gd's chase logic), and decelerate to a stop otherwise.
	# Update `_facing_dir` and call your facing/animation function as you move.
	pass


# ------------------------------------------------------------------ #
# Finite State Machine
# ------------------------------------------------------------------ #

## TODO: the main loop. Something like:
##   while not dead:
##       await _state_move()
##       if dead: return
##       await _state_telegraph()
##       if dead: return
##       await _state_shoot()
##       if dead: return
##       await _state_cooldown()
## Using `await` + `get_tree().create_timer(x).timeout` (or a custom signal for
## "arrived at waypoint") lets each state pause the coroutine without you
## needing a separate Timer node + signal callback per state.
func _run_state_machine() -> void:
	pass


## MOVE: pick a random next waypoint (TODO: bias against repeating the last one
## when there's more than one - this is where the "randomness" lives per the
## brief, NOT in the movement itself) and wait until arrived.
func _state_move() -> void:
	state = State.MOVE
	# TODO


## TELEGRAPH: stop, face + aim at the player, and give a clear visual tell
## (flash / pulse / wind-up animation) before firing.
func _state_telegraph() -> void:
	state = State.TELEGRAPH
	# TODO


## SHOOT: fire `shots_per_burst` projectiles, `shot_interval` apart, each aimed
## at the player's position at the moment of firing (see _fire_projectile).
func _state_shoot() -> void:
	state = State.SHOOT
	# TODO


## COOLDOWN: brief pause before the next MOVE - another safe window for the
## player to close the distance.
func _state_cooldown() -> void:
	state = State.COOLDOWN
	# TODO


# ------------------------------------------------------------------ #
# Helpers
# ------------------------------------------------------------------ #

## TODO: return a random Marker2D global_position from `waypoints`, avoiding
## `_last_waypoint` when there's more than one option. Remember to update
## `_last_waypoint`.
func _pick_next_point() -> Vector2:
	return global_position


func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


## TODO: instantiate `projectile_scene`, aim it at the player's current
## position (+ random spread within `aim_spread_degrees`), and call its
## setup(trans, damage, speed) - see bullet.gd / weapon.gd for the
## setup(Transform2D, damage, speed, max_range) convention this project uses.
func _fire_projectile() -> void:
	pass


## TODO: slice `idle_sheet` into 5 looping animations (one per ROW_* constant)
## using AtlasTexture regions, same idea as player.gd's _setup_death_animations().
func _build_idle_animations() -> void:
	pass


## TODO: pick the closest of the 5 rows for a direction vector and set
## sprite.flip_h for leftward angles - same idea as zombie_axe.gd's
## side/side_left mirroring, just with 5 tiers instead of 4.
## Tip: split by angle-from-horizontal into 5 even 45-degree bands
## (side / diagonal / vertical / diagonal / side) rather than comparing
## raw angle ranges directly - it's easy to mix up "pure down" vs "diagonal"
## if you only threshold the raw angle.
func _play_facing_animation(dir: Vector2) -> void:
	pass


func _gather_waypoints() -> void:
	pass


## Base Enemy has already set dead = true and emitted died() by the time this
## runs. No death sheet in the uploaded art yet, so TODO: fade out / play
## whatever you have, then queue_free() (don't forget to stop physics/movement
## and unblock the FSM coroutine if it might be mid-await).
func _die() -> void:
	pass
