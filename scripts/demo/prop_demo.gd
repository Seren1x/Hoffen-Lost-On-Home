extends CharacterBody2D
class_name PropDemoPlayer

## Minimal player used by the prop demo scene.
## - Arrow keys / WASD to move.
## - E to interact with Health/Ammo props.
## - Left-click to fire a simple "bullet" that destroys Destroyable props.
##
## Belongs to the "player" group and lives on collision layer 1, which the
## Interactable and Destroyable components look for by default.

const BULLET: PackedScene = preload("res://scenes/demo/DemoBullet.tscn")

@export var speed: float = 150.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 1


func _physics_process(_delta: float) -> void:
	var dir: Vector2 = Vector2(
		int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")),
		int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	).normalized()
	velocity = dir * speed
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var bullet: Area2D = BULLET.instantiate()
		bullet.global_position = global_position
		bullet.setup((get_global_mouse_position() - global_position).normalized())
		get_parent().add_child(bullet)
