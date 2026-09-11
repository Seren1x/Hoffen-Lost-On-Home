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
	add_to_group("enemy_bullets")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


## No bullet sprite uploaded yet - draw a simple placeholder circle so this
## works without needing an art asset. Swap for a Sprite2D once you have one.
func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)


func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	if max_range > 0.0:
		_traveled += speed * delta
		if _traveled >= max_range:
			queue_free()


## Set the bullet's starting transform and travel direction. Optionally override
## the damage/speed/max_range exported above. Match bullet.gd's signature so
## both projectile types are interchangeable.
func setup(trans: Transform2D, p_damage: int = -1, p_speed: float = -1.0, p_max_range: float = -1.0) -> void:
	transform = trans
	dir = trans.x.normalized()
	if p_damage >= 0:
		damage = p_damage
	if p_speed > 0.0:
		speed = p_speed
	if p_max_range > 0.0:
		max_range = p_max_range


## When the player (group "player") enters, damage them and disappear.
var _damaged: bool = false

func _on_body_entered(body: Node2D) -> void:
	if _damaged: return
	if body.is_in_group("player") and body.has_method("take_damage"):
		_damaged = true
		body.take_damage(damage)
		queue_free()


## Same idea, but via the player's Hurtbox (group "player_hurtbox" - see
## player.gd's _ready()) in case that's what actually overlaps first.
func _on_area_entered(area: Area2D) -> void:
	if _damaged: return
	if area.is_in_group("player_hurtbox"):
		_damaged = true
		var player := area.get_parent()
		if player != null and player.has_method("take_damage"):
			player.take_damage(damage)
		queue_free()
