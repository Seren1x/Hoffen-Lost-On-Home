class_name ZombieAxe
extends Enemy

## Zombie_Axe enemy. Chases the player, attacks in melee, flashes red when hit
## (via the base Enemy's hit flash), drops loot, and plays a death animation.
## HP and death handling live in the base Enemy class, which uses the universal
## Health component (health.gd).

@export var speed: float = 20.0
@export var chase_range: float = 400.0
@export var attack_range: float = 60.0
@export var damage: int = 10
@export var attack_cooldown: float = 2.5
## Playback speed for the attack animation (lower = slower, more visible swing).
const ATTACK_ANIM_SPEED: float = 1

## Attack hitbox offset per facing, used for the first attack (and the idle/chase
## resting position). Edit these in the inspector to tune where the hitbox sits.
@export var first_attack_offsets: Dictionary = {
	"right": Vector2(16, 0),
	"left": Vector2(-16, 0),
	"down": Vector2(0, 22),
	"up": Vector2(0, -22),
}

## Attack hitbox offset per facing for the second attack. The second swing is a
## different animation, so its hitbox can be positioned independently.
@export var second_attack_offsets: Dictionary = {
	"right": Vector2(16, 0),
	"left": Vector2(-16, 0),
	"down": Vector2(0, 22),
	"up": Vector2(0, -22),
}

## Sprite (AnimatedSprite2D) position offset per facing while playing the first
## attack. Lets you nudge the animation visually relative to the body.
@export var first_attack_anim_offsets: Dictionary = {
	"right": Vector2.ZERO,
	"left": Vector2.ZERO,
	"down": Vector2.ZERO,
	"up": Vector2.ZERO,
}

## Sprite (AnimatedSprite2D) position offset per facing while playing the second
## attack. The second swing is a different animation, so it can be shifted
## independently to line up with the body.
@export var second_attack_anim_offsets: Dictionary = {
	"right": Vector2(0,-15),
	"left": Vector2(0,-15),
	"down": Vector2.ZERO,
	"up": Vector2.ZERO,
}

var facing: String = "down"
var _can_attack: bool = true
var _current_attack: String = "first"

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var attack_timer: Timer = $AttackCooldown
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

## Base Enemy runs this hook during its _ready(). Point the hit-flash at our
## sprite and wire up animations.
func _ready_enemy() -> void:
	flash_sprite = sprite
	_reset_sprite_position()
	sprite.play("zombie_axe_down_idle")
	attack_timer.timeout.connect(_reset_attack)
	sprite.animation_finished.connect(_on_anim_finished)
	attack_area.monitoring = false
	attack_area.area_entered.connect(_on_attack_area_entered)
	_position_attack_area()

func _physics_process(_delta: float) -> void:
	if dead:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		velocity = Vector2.ZERO
		_play_idle()
		return
	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()
	if dist > chase_range:
		velocity = Vector2.ZERO
		_play_idle()
		return
	if dist <= attack_range:
		# In attack range: stop and attack when ready, otherwise hold position.
		velocity = Vector2.ZERO
		if _can_attack:
			_attack()
		elif not sprite.animation.ends_with("_attack"):
			# Let an in-progress attack animation finish; only idle once it's done.
			_play_idle()
	else:
		# Out of range: chase the player.
		velocity = to_player.normalized() * speed
		_update_facing(to_player.normalized())
		_play_walk()
	move_and_slide()

func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing = "left" if dir.x < 0 else "right"
	else:
		facing = "up" if dir.y < 0 else "down"
	# When chasing/idle, rest the hitbox on the first-attack offset.
	_current_attack = "first"
	_position_attack_area()

## Moves the attack hitbox in front of the zombie based on its facing direction
## and which attack variant is currently playing, so it stays relative to the
## zombie whenever it turns or switches between its two swings.
func _position_attack_area() -> void:
	var table: Dictionary = second_attack_offsets if _current_attack == "second" else first_attack_offsets
	attack_shape.position = table.get(facing, Vector2.ZERO)

## Positions the sprite (animation) to its configured offset for the current
## attack variant, so the second swing can be shifted visually relative to the body.
func _apply_attack_anim_offset() -> void:
	var table: Dictionary = second_attack_anim_offsets if _current_attack == "second" else first_attack_anim_offsets
	sprite.position = table.get(facing, Vector2.ZERO)

## Returns the sprite to its resting (no-attack) position.
func _reset_sprite_position() -> void:
	sprite.position = Vector2.ZERO

func _dir() -> String:
	match facing:
		"right":
			return "side"
		"left":
			return "side_left"
		_:
			return facing

func _play_idle() -> void:
	_reset_sprite_position()
	var a: String = "zombie_axe_" + _dir() + "_idle"
	if sprite.animation != a:
		sprite.play(a)

func _play_walk() -> void:
	_reset_sprite_position()
	var a: String = "zombie_axe_" + _dir() + "_walk"
	if sprite.animation != a:
		sprite.play(a)

func _attack() -> void:
	_can_attack = false
	attack_timer.start(attack_cooldown)
	# Alternate first/second attacks for variety.
	var n: String = "first" if randi() % 2 == 0 else "second"
	_current_attack = n
	var a: String = "zombie_axe_" + _dir() + "_" + n + "_attack"
	sprite.speed_scale = ATTACK_ANIM_SPEED
	sprite.play(a)
	_apply_attack_anim_offset()
	# Enable the melee hitbox for the duration of the swing.
	_activate_attack_area()

func _reset_attack() -> void:
	_can_attack = true

## Turns on the melee hitbox and immediately damages any player hurtbox already
## overlapping it when the swing starts.
func _activate_attack_area() -> void:
	_position_attack_area()
	attack_area.monitoring = true
	for area: Area2D in attack_area.get_overlapping_areas():
		_hit_player(area)

## Called when the player's hurtbox enters the attack area mid-swing.
func _on_attack_area_entered(area: Area2D) -> void:
	_hit_player(area)

## Damages the player if the overlapping area is the player's hurtbox.
func _hit_player(area: Area2D) -> void:
	if dead:
		return
	if not area.is_in_group("player_hurtbox"):
		return
	var player: Node2D = area.get_parent()
	if player != null and player.has_method("take_damage"):
		player.take_damage(damage)

func _on_anim_finished() -> void:
	if dead:
		queue_free()
	elif sprite.animation.ends_with("_attack"):
		sprite.speed_scale = 1.0
		_current_attack = "first"
		attack_area.monitoring = false
		_play_idle()

## Base Enemy has already set dead=true and emitted died. Add loot + death anim.
func _die() -> void:
	# Sometimes drop an ammo (or health) pickup for the player.
	if has_node("LootDropper"):
		$LootDropper.drop()
	sprite.speed_scale = 1.0
	_reset_sprite_position()
	velocity = Vector2.ZERO
	# Death only exists for side/side_left.
	var ddir: String = "side" if facing == "right" else "side_left"
	sprite.play("zombie_axe_" + ddir + "_first_death")
