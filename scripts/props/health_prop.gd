class_name HealthProp
extends Node2D

## Health pickup prop.
##
## Has an [Interactable] child. When the player interacts with it, the player is
## healed by [member heal_amount] and this prop is consumed (queue_free).
## The heal targets the interactor, so it works across player setups.

@export var heal_amount: int = 5

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(interactor: Node2D) -> void:
	_apply_heal(interactor)
	queue_free()


## Heals any supported player target:
## 1. A "Health" component child (components/health.gd).
## 2. A take_healing() / heal() method on the target.
## 3. A plain `health` int property (with optional `max_health` clamp).
func _apply_heal(target: Node2D) -> void:
	if target == null:
		return

	var health: Health = target.get_node_or_null("Health") as Health
	if health:
		health.take_healing(heal_amount)
		return

	if target.has_method("take_healing"):
		target.take_healing(heal_amount)
		return
	if target.has_method("heal"):
		target.heal(heal_amount)
		return

	if "health" in target:
		var current: Variant = target.get("health")
		if typeof(current) == TYPE_INT:
			var new_health: int = current + heal_amount
			if "max_health" in target:
				var maximum: Variant = target.get("max_health")
				if maximum is int:
					new_health = mini(new_health, maximum)
			target.set("health", new_health)
