extends Node2D


@onready var _progress: TaskManager = $TaskManager
@onready var _hud: HUD = $HUD

func _ready() -> void:
	_define_tasks()
	_connect_triggers()          # whatever signals YOUR level needs
	_connect_task_signals()
	_progress.activate("your_task_id")   # kick off the starting task


func _define_tasks() -> void:
	var task := TaskData.new()
	task.id = "your_task_id"
	task.title = "Human-Readable Title"
	task.description = "Shown in the task panel."

	var obj := TaskObjective.new()
	obj.type = TaskObjective.Type.KILL      # just a label, see section 3
	obj.description = "Defeat zombies"
	obj.target_id = "zombie"                # also just a label
	obj.required = 5
	task.objectives.append(obj)
	
	var obj_2 := TaskObjective.new()
	obj.type = TaskObjective.Type.KILL      # just a label, see section 3
	obj.description = "Defeat zombies"
	obj.target_id = "zombie"                # also just a label
	obj.required = 5

	# For a multi-objective task, just append more TaskObjective instances.
	_progress.register(task)


#func _connect_triggers() -> void:
	## Wherever the real gameplay event happens, call advance():
	#for raider in get_tree().get_nodes_in_group("raiders"):
		#raider.died.connect(func(): _progress.advance("your_task_id", 0, 1))

func _connect_triggers() -> void:
	for zombie: ZombieAxe in get_tree().get_nodes_in_group("enemies"):
		if not zombie.died.is_connected(_on_zombie_died):
			zombie.died.connect(_on_zombie_died)

func _on_zombie_died() -> void:
	_progress.advance("your_task_id", 0, 1)

func _connect_task_signals() -> void:
	_progress.task_activated.connect(_on_task_activated)
	_progress.objective_advanced.connect(_on_objective_advanced)
	_progress.task_completed.connect(_on_task_completed)

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
