class_name AmmoProp
extends Node2D

## Ammo pickup prop.
##
## Has an [Interactable] child. When the player interacts with it, the player's
## weapon is given [member ammo_amount] ammo and this prop is consumed.
## Works with the existing Weapon system (weapon.gd), found on the player or in
## the "weapon" group.

@export var ammo_amount: int = 5

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(interactor: Node2D) -> void:
	_add_ammo(interactor)
	queue_free()


func _add_ammo(interactor: Node2D) -> void:
	var weapon: Node = _find_weapon(interactor)
	if weapon == null:
		return

	# Preferred: the Weapon component exposes an add_ammo() method.
	if weapon.has_method("add_ammo"):
		weapon.add_ammo(ammo_amount)
		return
	# Fallback: reload refills to max.
	if weapon.has_method("weapon_reload"):
		weapon.weapon_reload()
		return
	# Last resort: modify the ammo properties directly.
	if "current_ammo" in weapon:
		var current: Variant = weapon.get("current_ammo")
		if typeof(current) == TYPE_INT:
			var new_ammo: int = current + ammo_amount
			if "max_ammo" in weapon:
				var maximum: Variant = weapon.get("max_ammo")
				if maximum is int:
					new_ammo = mini(new_ammo, maximum)
			weapon.set("current_ammo", new_ammo)


func _find_weapon(interactor: Node2D) -> Node:
	# Prefer the weapon on the interactor itself (old Player.tscn has a "Weapon" child).
	if interactor != null:
		var child: Node = interactor.get_node_or_null("Weapon")
		if child:
			return child
	# Otherwise look for any weapon in the "weapon" group.
	for node: Node in get_tree().get_nodes_in_group("weapon"):
		return node
	return null
