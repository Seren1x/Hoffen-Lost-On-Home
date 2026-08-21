class_name PlayerHitbox
extends Area2D

## Melee hitbox used by the player's bat attack.
## While active it detects anything in the "enemies" group that overlaps it and
## calls take_damage(damage) on it. Each target can only be hit once per swing.

@export var damage: int = 10

var _hit_this_swing: Array[Node] = []

func _ready() -> void:
	monitoring = false
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

## Called when a bat swing starts. Enables detection and immediately hits any
## enemy already overlapping at the moment the swing begins.
func activate() -> void:
	_hit_this_swing.clear()
	monitoring = true
	for body: Node2D in get_overlapping_bodies():
		_apply_damage(body)
	for area: Area2D in get_overlapping_areas():
		_apply_damage(area)

## Called when the swing ends. Disables detection.
func deactivate() -> void:
	monitoring = false
	_hit_this_swing.clear()

func _on_body_entered(body: Node2D) -> void:
	_apply_damage(body)

func _on_area_entered(area: Area2D) -> void:
	_apply_damage(area)

func _apply_damage(target: Node) -> void:
	if not target.is_in_group("enemies"):
		return
	if _hit_this_swing.has(target):
		return
	if not target.has_method("take_damage"):
		return
	_hit_this_swing.append(target)
	target.take_damage(damage)
