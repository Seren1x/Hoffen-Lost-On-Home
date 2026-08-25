class_name TaskData
extends Resource
## A game progress milestone — story chapter, level unlock, or objective chain.
## No rewards; purely tracks what the player has accomplished.

enum State { INACTIVE, ACTIVE, COMPLETED, FAILED }

@export var id: StringName
@export var title: String
@export_multiline var description: String = ""
@export var objectives: Array[TaskObjective] = []
@export var prerequisites: Array[StringName] = []  ## Task IDs that must be completed first

var state: State = State.INACTIVE


func _to_string() -> String:
	return "TaskData(%s: %s [%s])" % [id, title, State.keys()[state]]


## Returns 0.0–1.0 overall progress across all objectives.
func progress_ratio() -> float:
	if objectives.is_empty():
		return 1.0 if state == State.COMPLETED else 0.0
	var total: float = 0.0
	for obj: TaskObjective in objectives:
		total += obj.progress_ratio()
	return total / float(objectives.size())


## Check if all objectives are met.
func is_complete() -> bool:
	for obj: TaskObjective in objectives:
		if not obj.is_complete():
			return false
	return true
