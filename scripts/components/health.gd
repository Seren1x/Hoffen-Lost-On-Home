# Health Component by Zaura
# Version 1.0
# Github: https://github.com/ZauraGS
# BlueSky: https://bsky.app/profile/zaura-dev.bsky.social

class_name Health
extends Node

enum TYPE { DAMAGE, HEALING, RESURRECTION }

## The Health Component is used to give any node it's attached to health related functions.
##
## This component offers a variety of functions that can be personalized for each instance, including clamping [member current_health] values, ignoring all damage taken,
## exceeding [member max_health], and automatically emitting signals for damaging and healing events.[br][br]
##
## There are three primary methods for interacting with health.[br]
## [method take_damage][br]
## [method take_healing][br]
## [method resurrect][br][br]
## Another two methods are also provided to forcibly cause damage and healing which [u]can[/u] ignore [member god_mode], primarily used for scripting interactions.[br]
## [method force_damage][br]
## [method force_heal][br][br]

signal health_changed(current_amount: int, max_amount: int) ## Emitted every time [member current_health] is changed in a neutral context, should be used with interface functions
signal damaged(amount: int) ## Emitted when [member current_health] is changed in a negative context.
signal healed(amount: int) ## Emitted when [member current_health] is changed in a postive context.
signal resurrected ## Emitted when [member current_health] was at 0, and now is positive.
signal died(overkill: int) ## Emitted when [member current_health] has reached 0.

@export var max_health: int = 10: ## The maximum amount of [member current_health] this component can have normally. By default on creation current [member current_health] will be set to this value.
	set(value):
		var previous: int = max_health
		max_health = value
		if heal_difference:
			current_health += max_health - previous
		current_health = clamp(current_health, 0, max_health)
		health_changed.emit(current_health, max_health)

@export var exceed_maximum_health: bool = false ## Allows current [member current_health] to exceed [member max_health], used in niche situations.
@export var heal_difference: bool = true ## When modifying [member max_health] if it should grant the [member current_health] gained from [member max_health] increasing.
@export var god_mode: bool = false ## Causes all damage to be ignored unless forced by [method force_damage]. This does not stop healing from occuring.

var current_health: int = max_health: ## The current health, Will clamp any value changes to 0 or [member max_health] unless [member exceed_maximum_health] is enabled.
	set(value):
		if exceed_maximum_health:
			current_health = max(0, value)
		else:
			current_health = clamp(value, 0, max_health)
		health_changed.emit(current_health, max_health)
var dead: bool = false ## Used for resurrection purposes.

#region Public Functions

## The Public Method to negatively effect [member current_health].
func take_damage(damage: int) -> void:
	_change_health(damage, TYPE.DAMAGE)

## The Public Method to postively effect [member current_health].
func take_healing(healing: int) -> void:
	_change_health(healing, TYPE.HEALING)

## The Public Method to resurrect if [member dead].
func resurrect(healing: int) -> void:
	_change_health(healing, TYPE.RESURRECTION)

#endregion

#region Private Functions

## The Private method to effect the [member current_health] of the component.[br][br]
## Expected Operations:[br]
## 1. You can always be healed unless [member dead].[br]
## 2. You can only be resurrected when [member dead].[br]
## 3. If [member god_mode] is enabled, exit early.[br]
## 4. Lastly if [member current_health] is equal to 0, [signal died] will be emitted with overkilled amount.[br]
func _change_health(amount: int, type: TYPE) -> void:
	match type:
		TYPE.HEALING:
			if dead:
				return
			current_health += amount
			healed.emit(amount)
		TYPE.RESURRECTION:
			if not dead:
				return
			dead = false
			current_health += amount
			healed.emit(amount)
			resurrected.emit()
		TYPE.DAMAGE:
			if god_mode:
				return
			var overkill: int = amount - current_health
			current_health -= amount
			damaged.emit(amount)
			if current_health <= 0:
				dead = true
				died.emit(overkill)

#endregion

#region Force Methods

## This method will forcibly cause damage, and can be set to not ignore [member god_mode].[br]
## [u]This is not the intended way to cause damage or healing and shoud be used only for scripting scenarios.[/u]
func force_damage(amount: int, ignore_god_mode: bool = true) -> void:
	var current_god_status: bool = god_mode
	if ignore_god_mode:
		god_mode = false
	_change_health(amount, TYPE.DAMAGE)
	god_mode = current_god_status

## This method will forcibly increase [member current_health] and cause resurrection to happen.[br]
## [u]This is not the intended way to cause damage or healing and shoud be used only for scripting scenarios.[/u]
func force_heal(amount: int) -> void:
	if dead:
		_change_health(amount, TYPE.RESURRECTION)
	else:
		_change_health(amount, TYPE.HEALING)

#endregion
