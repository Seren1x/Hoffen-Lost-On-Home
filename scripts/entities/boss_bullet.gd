extends Area2D

## Boss projectile template.
##
## Mirrors bullet.gd's setup(trans, damage, speed, max_range) convention (the
## same one Weapon.player_shoot() uses) so this drops in anywhere a bullet
## scene is expected - just aimed at the player instead of enemies.
##
## Key behaviour to preserve: travel in a STRAIGHT line once fired (aim is
## decided once, at setup time, by whoever spawns this - e.g. Boss._fire_projectile).
## Do not make this home in on the player after launch; that's what keeps it dodgeable.

@export var speed: float = 260.0
@export var damage: int = 8
## Max distance the bullet can travel before disappearing. <= 0 means unlimited.
@export var max_range: float = 700.0
@export var radius: float = 6.0
@export var color: Color = Color(0.85, 0.2, 0.25)

var dir: Vector2 = Vector2.RIGHT
var _traveled: float = 0.0


func _ready() -> void:
	# TODO: join a group (e.g. "enemy_bullets") if other systems should be able
	# to detect this projectile, and connect body_entered / area_entered.
	pass


## No bullet sprite uploaded yet - draw a simple placeholder circle so this
## works without needing an art asset. Swap for a Sprite2D once you have one.
func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)


func _physics_process(delta: float) -> void:
	# TODO: move along `dir` at `speed`, and queue_free() once `max_range` is
	# exceeded (see bullet.gd for the exact pattern).
	pass


## Set the bullet's starting transform and travel direction. Optionally override
## the damage/speed/max_range exported above. Match bullet.gd's signature so
## both projectile types are interchangeable.
func setup(trans: Transform2D, p_damage: int = -1, p_speed: float = -1.0, p_max_range: float = -1.0) -> void:
	# TODO: apply trans, derive `dir` from trans.x.normalized(), and override
	# damage/speed/max_range when the caller passed non-default values.
	pass


## TODO: when the player's CharacterBody2D (group "player") enters, call its
## take_damage(damage) and queue_free() - see player.gd's take_damage().
func _on_body_entered(body: Node2D) -> void:
	pass


## TODO: same idea, but via the player's Hurtbox (group "player_hurtbox" - see
## player.gd's _ready()) in case that's what actually overlaps first.
func _on_area_entered(area: Area2D) -> void:
	pass
