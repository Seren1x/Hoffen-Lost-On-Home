class_name LootDropper
extends Node

## Drops a pickup at the owner's position when [method drop] is called.
##
## Attach to any enemy and call [method drop] from its death handler to make it
## sometimes leave ammo (or health) behind. The probability is [member drop_chance].

signal dropped(pickup: Node2D)

@export_range(0.0, 1.0) var drop_chance: float = 0.3
@export var loot_type: String = "ammo"  # "ammo" or "health"
@export var loot_amount: int = 5

const HEALTH_PICKUP: PackedScene = preload("res://scenes/props/HealthProp.tscn")
const AMMO_PICKUP: PackedScene = preload("res://scenes/props/AmmoProp.tscn")


## Rolls the chance and, if it succeeds, spawns the pickup at the owner's position.
func drop() -> void:
	if randf() > drop_chance:
		return
	var pickup: Node2D
	if loot_type == "health":
		pickup = HEALTH_PICKUP.instantiate()
		pickup.set("heal_amount", loot_amount)
	else:
		pickup = AMMO_PICKUP.instantiate()
		pickup.set("ammo_amount", loot_amount)

	var owner_node: Node2D = get_parent() as Node2D
	pickup.global_position = owner_node.global_position if owner_node else Vector2.ZERO
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(pickup)
	dropped.emit(pickup)
