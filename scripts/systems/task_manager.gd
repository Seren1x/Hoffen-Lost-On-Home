class_name TaskManager
extends Node
## Manages game progress tasks. Add as a child of your game scene or as an autoload.
##
## Usage:
##   var tm := TaskManager.new()
##   add_child(tm)
##   tm.register(task_data)
##   tm.activate("find_key")
##   tm.advance("find_key", 0, 1)  # progress objective 0 by 1
##
## Signals let UI react without coupling:
##   tm.task_activated.connect(ui._on_task)
##   tm.task_completed.connect(ui._on_done)
##   tm.objective_advanced.connect(ui._on_progress)

signal task_activated(task_id: StringName)
signal task_completed(task_id: StringName)
signal task_failed(task_id: StringName)
signal objective_advanced(task_id: StringName, objective_index: int, current: int, required: int)

var _tasks: Dictionary = {}  ## StringName -> TaskData


## Register a TaskData resource. Tasks start INACTIVE.
func register(task: TaskData) -> void:
	task.state = TaskData.State.INACTIVE
	for obj: TaskObjective in task.objectives:
		obj.reset()
	_tasks[task.id] = task


## Register multiple tasks at once.
func register_all(tasks: Array[TaskData]) -> void:
	for t: TaskData in tasks:
		register(t)


## Activate a task. Fails if prerequisites aren't met or already active.
func activate(task_id: StringName) -> bool:
	var task: TaskData = _tasks.get(task_id)
	if not task:
		push_warning("TaskManager: unknown task '%s'" % task_id)
		return false
	if task.state != TaskData.State.INACTIVE:
		return false
	for prereq_id: StringName in task.prerequisites:
		var prereq: TaskData = _tasks.get(prereq_id)
		if not prereq or prereq.state != TaskData.State.COMPLETED:
			return false
	task.state = TaskData.State.ACTIVE
	task_activated.emit(task_id)
	return true


## Manually mark a task completed.
func complete(task_id: StringName) -> bool:
	var task: TaskData = _tasks.get(task_id)
	if not task or task.state != TaskData.State.ACTIVE:
		return false
	task.state = TaskData.State.COMPLETED
	task_completed.emit(task_id)
	return true


## Mark a task as failed.
func fail(task_id: StringName) -> bool:
	var task: TaskData = _tasks.get(task_id)
	if not task or task.state != TaskData.State.ACTIVE:
		return false
	task.state = TaskData.State.FAILED
	task_failed.emit(task_id)
	return true


## Advance an objective by `amount`. Auto-completes task if all objectives met.
func advance(task_id: StringName, objective_index: int, amount: int = 1) -> void:
	var task: TaskData = _tasks.get(task_id)
	if not task or task.state != TaskData.State.ACTIVE:
		return
	if objective_index < 0 or objective_index >= task.objectives.size():
		push_warning("TaskManager: objective %d out of range for '%s'" % [objective_index, task_id])
		return
	var obj: TaskObjective = task.objectives[objective_index]
	var was_complete: bool = obj.is_complete()
	obj.increment(amount)
	objective_advanced.emit(task_id, objective_index, obj.current, obj.required)
	if not was_complete and task.is_complete():
		complete(task_id)


## Set an objective to a specific value. Auto-completes task if all met.
func set_objective(task_id: StringName, objective_index: int, value: int) -> void:
	var task: TaskData = _tasks.get(task_id)
	if not task or task.state != TaskData.State.ACTIVE:
		return
	if objective_index < 0 or objective_index >= task.objectives.size():
		return
	var obj: TaskObjective = task.objectives[objective_index]
	var was_complete: bool = obj.is_complete()
	obj.current = clampi(value, 0, obj.required)
	objective_advanced.emit(task_id, objective_index, obj.current, obj.required)
	if not was_complete and task.is_complete():
		complete(task_id)


## Get a task by ID.
func get_task(task_id: StringName) -> TaskData:
	return _tasks.get(task_id)


## All registered tasks.
func all() -> Array[TaskData]:
	var result: Array[TaskData] = []
	for t: TaskData in _tasks.values():
		result.append(t)
	return result


## Only active tasks.
func active() -> Array[TaskData]:
	var result: Array[TaskData] = []
	for t: TaskData in _tasks.values():
		if t.state == TaskData.State.ACTIVE:
			result.append(t)
	return result


## Only completed tasks.
func completed() -> Array[TaskData]:
	var result: Array[TaskData] = []
	for t: TaskData in _tasks.values():
		if t.state == TaskData.State.COMPLETED:
			result.append(t)
	return result


func is_active(task_id: StringName) -> bool:
	var task: TaskData = _tasks.get(task_id)
	return task != null and task.state == TaskData.State.ACTIVE


func is_completed(task_id: StringName) -> bool:
	var task: TaskData = _tasks.get(task_id)
	return task != null and task.state == TaskData.State.COMPLETED
