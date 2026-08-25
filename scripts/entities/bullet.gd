extends Area2D

@export var speed: float = 800.0
@export var damage: int = 30

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += transform.x * speed * delta

func setup(trans: Transform2D):
	transform = trans
