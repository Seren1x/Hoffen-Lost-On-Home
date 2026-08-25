class_name Bullet
extends Area2D

## Bullet projectile fired by the player's gun. Travels in a direction, damages
## the first enemy it touches (group "enemies" with take_damage), and disappears.

@export var speed: float = 600.0
@export var damage: int = 20
@export var lifetime: float = 2.0
## Max travel distance before the bullet disappears. <= 0 means unlimited.
## Useful for short-range weapons like the shotgun.
@export var max_range: float = -1.0

var dir: Vector2 = Vector2.RIGHT
var _traveled: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	var timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

## Set the travel direction (also rotates the sprite to face it).
func setup(direction: Vector2) -> void:
	dir = direction.normalized()
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	if max_range > 0.0:
		_traveled += speed * delta
		if _traveled >= max_range:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") and area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
