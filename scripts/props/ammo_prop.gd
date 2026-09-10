class_name AmmoProp
extends Node2D

## Ammo pickup prop.
##
## Has an [Interactable] child. When the player interacts with it, the equipped
## weapon's RESERVE pool is given [member magazines] full magazines of spare
## rounds (1 prop = 1 magazine = the weapon's max_ammo rounds) and this prop is
## consumed. Works with the existing Weapon system (weapon.gd), found on the
## player or in the "weapon" group.

## How many full magazines this prop grants (1 = one magazine).
@export var magazines: int = 1

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)


func _on_interacted(interactor: Node2D) -> void:
	_give_magazines(interactor)
	queue_free()


func _give_magazines(interactor: Node2D) -> void:
	var weapon: Node = _find_weapon(interactor)
	if weapon == null:
		return

	# Preferred: the Weapon component's per-magazine reserve API.
	if weapon.has_method("add_magazines"):
		weapon.add_magazines(magazines)
		if weapon.has_method("get_mag"):
			print("[AmmoProp] +%d mag -> mag=%d reserve=%d" % [
				magazines, weapon.get_mag(), weapon.get_reserve()])
		return
	# Fallback for older Weapon builds without a reserve pool: top up the mag.
	if weapon.has_method("add_ammo"):
		weapon.add_ammo(magazines * 12)


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
