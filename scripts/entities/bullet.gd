extends Area2D

@export var speed: float = 800.0
@export var damage: int = 30

func _ready() -> void:
	# Join the "bullets" group so Destroyable props (and anything else reacting
	# to projectiles) can detect and react to this bullet.
	add_to_group("bullets")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += transform.x * speed * delta

func setup(trans: Transform2D):
	transform = trans

# The Bullet.tscn scene wires the child "Hitbox" area's area_entered to this
# method. Kept so the bullet damages anything with take_damage() (enemies).
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
