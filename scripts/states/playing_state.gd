## Hosts whichever level is currently being played and bridges gameplay-level
## input (pause) to StateManager. No base class — StateManager calls
## state_enter()/state_exit() via duck typing (see state_manager.gd).
extends Node2D
class_name PlayingState

## Default level to load. Pass {"level": some_packed_scene} to change_state()
## if you ever need to start on a different level (e.g. for a level-select).
@export var default_level: PackedScene = preload("res://scenes/levels/Outskirt.tscn")

var _level: Node = null

func state_enter(data: Dictionary = {}) -> void:
	var level_scene: PackedScene = data.get("level", default_level)
	_level = level_scene.instantiate()
	add_child(_level)
	# Restore weapon data carried over from a previous level.
	if not StateManager.saved_weapon_data.is_empty():
		call_deferred("_restore_weapons_from_save")


func _restore_weapons_from_save() -> void:
	var weapon := _level.get_tree().get_first_node_in_group("weapon") as Weapon
	if weapon and weapon.has_method("restore_save_data"):
		weapon.restore_save_data(StateManager.saved_weapon_data)
		StateManager.saved_weapon_data = {}


## The playing level is a "world" state: it must stay visible behind overlay
## states (pause/settings), so StateManager does not hide it when they stack.
func is_world_state() -> bool:
	return true

func state_exit() -> void:
	if _level:
		# Save weapon data before destroying the level so it survives the transition.
		var weapon := _level.get_tree().get_first_node_in_group("weapon") as Weapon
		if weapon and weapon.has_method("get_save_data"):
			StateManager.saved_weapon_data = weapon.get_save_data()
		_level.queue_free()
		_level = null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		StateManager.push_state("paused", _collect_pause_data())


## Gathers the live gameplay snapshot the PauseMenu shows instead of the HUD:
## player health, stamina/energy, the equipped weapon, and the active task's
## objective. All lookups are generic (via groups / node names), so this works
## for any level. Missing pieces are simply omitted — PauseMenu degrades
## gracefully and only shows panels for the data that's present.
func _collect_pause_data() -> Dictionary:
	var data := {}

	var player := get_tree().get_first_node_in_group("player")
	if player:
		var health := player.get_node_or_null("Health")
		if health:
			data["hp"] = health.current_health
			data["max_hp"] = health.max_health
		if player.get("stamina") != null:
			data["energy"] = player.stamina
			data["max_energy"] = player.max_stamina

	var weapon := get_tree().get_first_node_in_group("weapon")
	if weapon:
		var def = weapon.get_current_definition() if weapon.has_method("get_current_definition") else null
		if def:
			data["weapon_name"] = def.display_name
			data["weapon_ammo"] = weapon.get_mag() if weapon.has_method("get_mag") else 0
			data["weapon_max_ammo"] = def.max_ammo

	# Active task + objective (TaskManager is a direct child of every level).
	if _level:
		var tm := _level.get_node_or_null("TaskManager")
		if tm and tm.has_method("active"):
			var actives: Array = tm.active()
			if not actives.is_empty():
				var task = actives[0]
				data["task_title"] = task.title
				var objs: Array = []
				for o in task.objectives:
					objs.append({
						"description": o.description,
						"current": o.current,
						"required": o.required,
					})
				data["task_objectives"] = objs

	return data
