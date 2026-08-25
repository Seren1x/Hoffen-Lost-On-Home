class_name TaskObjective
extends Resource
## A single objective within a task (e.g. "Collect 5 herbs", "Kill 3 zombies").

enum Type { COLLECT, KILL, TALK, REACH, CUSTOM }

@export var type: Type = Type.CUSTOM
@export var description: String = ""
@export var target_id: StringName = ""   ## Item ID, NPC name, location ID, etc.
@export var required: int = 1

var current: int = 0


func progress_ratio() -> float:
	if required <= 0:
		return 1.0
	return clampf(float(current) / float(required), 0.0, 1.0)


func is_complete() -> bool:
	return current >= required


func increment(amount: int = 1) -> void:
	current = mini(current + amount, required)


func reset() -> void:
	current = 0
