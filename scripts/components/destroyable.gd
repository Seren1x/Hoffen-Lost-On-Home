class_name Destroyable
extends Area2D

## Reusable "make it destroyable" component (observer pattern).
##
## Attach this as a child of any prop/object. It detects hits from:
## - anything carrying a [Hitbox] component (class Hitbox), or
## - projectiles in the "bullets" group.
##
## When its HP reaches 0 it emits [signal destroyed], can drop a pickup
## ([enum Loot]), and optionally frees the whole prop ([member free_on_destroy]).
## The prop's own script (or anything else) can connect to [signal destroyed]
## to run custom logic before the object disappears.

signal destroyed

## What the destroyed prop leaves behind.
enum Loot { NONE, HEALTH, AMMO }

@export var hp: int = 5
## Set to HEALTH or AMMO to drop a pickup when destroyed. NONE = plain obstacle
## (e.g. a road-block the player must shoot through to continue).
@export var loot: Loot = Loot.NONE
## Heal/ammo amount given to the dropped pickup.
@export var loot_amount: int = 5
## If true, the whole prop (this component's parent) is freed when destroyed.
@export var free_on_destroy: bool = true

const HEALTH_PICKUP: PackedScene = preload("res://scenes/props/HealthProp.tscn")
const AMMO_PICKUP: PackedScene = preload("res://scenes/props/AmmoProp.tscn")


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullets"):
		_apply_damage(1)


func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		_apply_damage(area.damage)
	elif area.is_in_group("bullets"):
		_apply_damage(1)


func _apply_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	if hp <= 0:
		_destroy()


func _destroy() -> void:
	destroyed.emit()
	if loot != Loot.NONE:
		_drop_loot()
	if free_on_destroy:
		var parent: Node = get_parent()
		queue_free()
		if parent != null and parent != get_tree().root:
			parent.queue_free()


func _drop_loot() -> void:
	var pickup: Node2D
	match loot:
		Loot.HEALTH:
			pickup = HEALTH_PICKUP.instantiate()
			pickup.set("heal_amount", loot_amount)
		Loot.AMMO:
			pickup = AMMO_PICKUP.instantiate()
			pickup.set("ammo_amount", loot_amount)
		_:
			return
	pickup.global_position = global_position
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(pickup)
