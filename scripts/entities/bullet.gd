extends Area2D

## Bullet projectile fired by the player's gun. Travels in the direction it was
## fired, damages the first enemy it touches (group "enemies" with take_damage),
## and disappears after hitting an enemy or travelling its max range.

@export var speed: float = 800.0
@export var damage: int = 5
## Max distance the bullet can travel before disappearing. <= 0 means unlimited.
@export var max_range: float = 200.0

var dir: Vector2 = Vector2.RIGHT
var _traveled: float = 0.0

func _ready() -> void:
	# Join the "bullets" group so Destroyable props (and anything else reacting
	# to projectiles) can detect and react to this bullet.
	add_to_group("bullets")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

# Move every physics frame so collision detection stays reliable.
func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	# Disappear after travelling max_range (in pixels).
	if max_range > 0.0:
		_traveled += speed * delta
		if _traveled >= max_range:
			queue_free()

## Set the bullet's starting transform and travel direction. Optionally override
## the damage/speed exported by the weapon firing it.
func setup(trans: Transform2D, p_damage: int = -1, p_speed: float = -1.0) -> void:
	transform = trans
	dir = trans.x.normalized()
	if p_damage >= 0:
		damage = p_damage
	if p_speed > 0.0:
		speed = p_speed

# The bullet damages an enemy (a CharacterBody2D in the "enemies" group) the
# moment it touches it, then disappears.
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()

# Also handles enemies exposed as an Area2D (e.g. a Hurtbox) in the "enemies" group.
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") and area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
