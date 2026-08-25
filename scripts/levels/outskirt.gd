extends Node2D
class_name OutskirtLevel
## Level script for Outskirt. Defines and manages game progress tasks.

@onready var _progress: TaskManager = $TaskManager
@onready var _hud: HUD = $HUD
@onready var _player: Player = $YSortEntities/Player


func _ready() -> void:
	_define_tasks()
	_connect_enemies()
	_connect_player_health()
	_connect_task_signals()
	_progress.activate("escape_forest")


func _define_tasks() -> void:
	# ── Chapter 1: Escape the Forest ──
	var ch1 := TaskData.new()
	ch1.id = "escape_forest"
	ch1.title = "Escape the Forest"
	ch1.description = "Fight through the zombies and find your way out of the woods."

	var kill_zombies := TaskObjective.new()
	kill_zombies.type = TaskObjective.Type.KILL
	kill_zombies.description = "Defeat zombies"
	kill_zombies.target_id = "zombie"
	kill_zombies.required = 3
	ch1.objectives.append(kill_zombies)

	_progress.register(ch1)

	# ── Chapter 2: Find Shelter (requires ch1) ──
	var ch2 := TaskData.new()
	ch2.id = "find_shelter"
	ch2.title = "Find Shelter"
	ch2.description = "Locate a safe place before nightfall."
	ch2.prerequisites = ["escape_forest"]

	var reach_shelter := TaskObjective.new()
	reach_shelter.type = TaskObjective.Type.REACH
	reach_shelter.description = "Reach the abandoned cabin"
	reach_shelter.target_id = "cabin"
	reach_shelter.required = 1
	ch2.objectives.append(reach_shelter)

	_progress.register(ch2)


func _connect_enemies() -> void:
	for zombie: ZombieAxe in get_tree().get_nodes_in_group("enemies"):
		if not zombie.died.is_connected(_on_zombie_died):
			zombie.died.connect(_on_zombie_died)


func _connect_player_health() -> void:
	_hud.update_health(_player.health, _player.max_health)


func _connect_task_signals() -> void:
	_progress.task_activated.connect(_on_task_activated)
	_progress.objective_advanced.connect(_on_objective_advanced)
	_progress.task_completed.connect(_on_task_completed)


func _on_zombie_died() -> void:
	_progress.advance("escape_forest", 0, 1)


# ── Task UI callbacks ──

func _on_task_activated(task_id: StringName) -> void:
	var task: TaskData = _progress.get_task(task_id)
	if not task:
		return
	_hud.show_task(task.title, task.objectives)


func _on_objective_advanced(_task_id: StringName, index: int, current: int, required: int) -> void:
	_hud.update_objective(index, current, required)


func _on_task_completed(_task_id: StringName) -> void:
	_hud.hide_task()
