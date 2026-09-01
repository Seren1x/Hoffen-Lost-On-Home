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


## The playing level is a "world" state: it must stay visible behind overlay
## states (pause/settings), so StateManager does not hide it when they stack.
func is_world_state() -> bool:
	return true

func state_exit() -> void:
	if _level:
		_level.queue_free()
		_level = null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		StateManager.push_state("paused", _collect_pause_data())


## TODO(you): Player has no Health component yet, so there's nothing real to
## report. Returning {} is intentional — PauseMenu.state_enter() already
## checks data.has("hp") and hides the stats panel when it's missing, so this
## degrades gracefully. Once Player has a Health node, populate hp/max_hp
## here (and drop "energy" entirely unless you actually build that system).
func _collect_pause_data() -> Dictionary:
	return {}
