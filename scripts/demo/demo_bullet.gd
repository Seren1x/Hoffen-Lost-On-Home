extends Area2D

## Tiny self-contained projectile used ONLY by the prop demo scene.
## It belongs to the "bullets" group, which the Destroyable component reacts to.
## It is deliberately decoupled from the project's real bullet scripts.

var dir: Vector2 = Vector2.RIGHT
@export var speed: float = 400.0
@export var lifetime: float = 1.0


func _ready() -> void:
	add_to_group("bullets")
	body_entered.connect(_on_body_entered)
	var timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)


func setup(direction: Vector2) -> void:
	dir = direction.normalized()
	rotation = dir.angle()


func _physics_process(delta: float) -> void:
	position += dir * speed * delta


func _on_body_entered(_body: Node2D) -> void:
	queue_free()
