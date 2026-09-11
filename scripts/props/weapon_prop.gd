class_name WeaponProp
extends Node2D

## Ground weapon pickup prop.
##
## Place one of the scenes from res://scenes/props/weapons/ anywhere in a level.
## When the player interacts with it (E):
##  - If the player does NOT own this weapon yet, it is added to their loadout
##    with a limited ammo bundle (full mag + [WeaponDefinition.pickup_reserve_ammo]
##    spare rounds, e.g. a Pistol reads 6/12) and is equipped immediately.
##  - If the player already owns it, the prop converts into spare rounds for it.
## Either way the prop is consumed.
##
## The sprite shows the same PNG used for the held weapon, so the pickup always
## matches what the player gets.

## Which weapon this prop grants.
@export var weapon_def: WeaponDefinition
## Overrides the spare rounds bundled with this pickup when >= 0. Leave at -1
## to use the weapon definition's pickup_reserve_ammo.
@export var reserve_override: int = -1

@onready var interactable: Interactable = $Interactable
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	# Safety net: if a scene forgot to set the sprite, fall back to the held-
	# weapon texture from the definition so the prop is never invisible.
	if weapon_def != null and sprite.texture == null:
		sprite.texture = weapon_def.sprite_texture


func _on_interacted(interactor: Node2D) -> void:
	var weapon: Weapon = _find_weapon(interactor)
	if weapon == null or weapon_def == null:
		return

	var reserve: int = reserve_override if reserve_override >= 0 else weapon_def.pickup_reserve_ammo
	var added: bool = weapon.add_weapon(weapon_def, reserve)
	if not added:
		# Already owned: the gun itself is spare parts — its bundled rounds go
		# to THAT weapon's reserve pool (not the equipped weapon's).
		if not weapon.add_reserve_to(weapon_def, reserve):
			weapon.add_ammo(reserve)
	print("[WeaponProp] %s pickup (new=%s) | its reserve now %d" % [
		weapon_def.display_name, str(added), weapon.get_reserve_of(weapon_def)])
	queue_free()


## Finds the player's Weapon node: a "Weapon" child of the interactor, else the
## first node in the "weapon" group.
func _find_weapon(interactor: Node2D) -> Weapon:
	if interactor != null:
		var child: Node = interactor.get_node_or_null("Weapon")
		if child is Weapon:
			return child
	return get_tree().get_first_node_in_group("weapon") as Weapon
