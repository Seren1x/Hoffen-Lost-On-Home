extends Node2D
class_name FinalMapLevel
## Level script for the Final Map (chapter 3). Defines the 5-step story task
## chain and wires dialogue to task completion, area approach, and item pickup.
## Mirrors OutskirtLevel / DowntownLevel's architecture
## (TaskManager/TaskData/TaskObjective + HUD + DialogueBox).
##
## NOTE ON A COUPLE OF ASSUMPTIONS (only two things I couldn't verify from the
## .tscn alone, since SniperRifleProp.tscn / Boss.tscn weren't provided):
##   1. SniperRifleProp is assumed to itself be (or directly contain) the
##      Interactable used for the pickup. _resolve_interactable() below
##      handles either case, so no path fix should be needed either way.
##   2. Boss is assumed to expose a `died` signal, same as ZombieAxe. If it's
##      named differently, tweak _connect_boss() / _on_boss_died() below.

@onready var _progress: TaskManager = $TaskManager
@onready var _hud: HUD = $HUD
@onready var _dialogue: DialogueBox = $DialogueBox

@onready var _player: CharacterBody2D = $YSortEntities/Player

@onready var _destination_area: Area2D = $QuestRelated/DestinationMarker2   # first waypoint
@onready var _weapon_pickup: Interactable = _resolve_interactable($SniperRifleProp)
@onready var _boss: Node2D = $YSortEntities/Monster/Boss
@onready var _end_level: Area2D = $QuestRelated/DestinationMarker          # final waypoint -> win

const SPEAKER_NAME := "Rain"

@onready var QUEST_MARKERS: Dictionary = {
	"move_to_point": [$QuestRelated/DestinationMarker2/Marker],
	"get_weapon": [$SniperRifleProp/Marker],
	"end_level": [$QuestRelated/DestinationMarker/Marker],
}

func _ready() -> void:
	_define_tasks()
	_connect_enemies()
	_connect_boss()
	_connect_triggers()
	_connect_task_signals()
	_hide_all_markers()
	_progress.activate("move_to_point")   # first task in the chain
	_player.player_died.connect(_on_player_died)


func _define_tasks() -> void:
	_register_task("move_to_point", "Move to the objective", TaskObjective.Type.REACH, "waypoint", 1, [])
	_register_task("get_weapon", "Retrieve the sniper rifle", TaskObjective.Type.COLLECT, "weapon", 1, ["move_to_point"])
	_register_task("eliminate_mutants", "Clear out the mutants", TaskObjective.Type.KILL, "mutant", 6, ["get_weapon"])
	_register_task("defeat_boss", "Take down the alpha", TaskObjective.Type.KILL, "boss", 1, ["eliminate_mutants"])
	_register_task("end_level", "Reach the extraction point", TaskObjective.Type.REACH, "waypoint", 1, ["defeat_boss"])


## Small helper so the 5-task chain above isn't repeated boilerplate.
func _register_task(id: String, title: String, obj_type: TaskObjective.Type, target_id: String, required: int, prereqs: Array[String]) -> void:
	var task := TaskData.new()
	task.id = id
	task.title = title
	task.prerequisites.assign(prereqs)

	var obj := TaskObjective.new()
	obj.type = obj_type
	obj.description = title
	obj.target_id = target_id
	obj.required = required
	task.objectives.append(obj)

	_progress.register(task)


## Returns node itself if it's already an Interactable, otherwise looks for an
## "Interactable" child — covers either way SniperRifleProp.tscn might be built.
func _resolve_interactable(node: Node) -> Interactable:
	if node == null:
		return null
	if node is Interactable:
		return node
	if node.has_node("Interactable"):
		return node.get_node("Interactable") as Interactable
	push_warning("FinalMapLevel: couldn't find an Interactable on/under %s — fix the path in _weapon_pickup." % node.name)
	return null


## Enemies placed directly in the scene (the 6 pre-placed ZombieAxe) — same
## pattern as OutskirtLevel for its pre-placed mutants.
func _connect_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is ZombieAxe and not node.died.is_connected(_on_mutant_died):
			node.died.connect(_on_mutant_died)


func _connect_boss() -> void:
	if _boss == null:
		return
	if _boss.has_signal("died"):
		_boss.died.connect(_on_boss_died)
	else:
		push_warning("FinalMapLevel: Boss node has no 'died' signal — update _connect_boss()/_on_boss_died() to match your Boss script.")


func _hide_all_markers() -> void:
	for markers: Array in QUEST_MARKERS.values():
		for marker: Sprite2D in markers:
			if is_instance_valid(marker):
				marker.visible = false


## Wires every physical trigger in the level to its matching task step.
func _connect_triggers() -> void:
	if _destination_area:
		_destination_area.body_entered.connect(_on_destination_reached)
	if _weapon_pickup:
		_weapon_pickup.interacted.connect(_on_weapon_picked_up)
	if _end_level:
		_end_level.body_entered.connect(_on_level_ended)


# ── Trigger callbacks: advance the task AND show the matching dialogue line ──

func _on_destination_reached(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not _progress.is_active("move_to_point"):
		return   # already triggered — ignore repeat visits
	_progress.advance("move_to_point", 0, 1)
	_dialogue.show_dialogue(SPEAKER_NAME, "This is it. End of the line.")
	_destination_area.set_deferred("monitoring", false)


func _on_weapon_picked_up(_interactor: Node2D) -> void:
	_progress.advance("get_weapon", 0, 1)
	_dialogue.show_dialogue(SPEAKER_NAME, "A sniper rifle. This'll help me thin the herd from a distance.")


func _on_mutant_died() -> void:
	var was_active: bool = _progress.is_active("eliminate_mutants")
	_progress.advance("eliminate_mutants", 0, 1)
	if was_active and _progress.is_completed("eliminate_mutants"):
		_dialogue.show_dialogue(SPEAKER_NAME, "That clears the mutants. Just one thing left out here.")


func _on_boss_died() -> void:
	if not _progress.is_active("defeat_boss"):
		return
	_progress.advance("defeat_boss", 0, 1)
	_dialogue.show_dialogue(SPEAKER_NAME, "It's down. This nightmare is finally over.")


func _on_level_ended(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not _progress.is_active("end_level"):
		return

	_progress.advance("end_level", 0, 1)
	_dialogue.show_monologue("Level end")

	# Final Map is the last chapter — this is where the whole trilogy ends,
	# so change_state() hands off to the win screen instead of another level.
	StateManager.change_state("end_screen")


# ── Task chain progression + HUD relay ──

func _connect_task_signals() -> void:
	_progress.task_activated.connect(_on_task_activated)
	_progress.objective_advanced.connect(_on_objective_advanced)
	_progress.task_completed.connect(_on_task_completed)


func _on_task_activated(task_id: StringName) -> void:
	var task: TaskData = _progress.get_task(task_id)
	if not task:
		return
	_hud.show_task(task.title, task.objectives)
	for marker: Sprite2D in QUEST_MARKERS.get(task_id, []):
		if is_instance_valid(marker):
			marker.visible = true


func _on_objective_advanced(_task_id: StringName, index: int, current: int, required: int) -> void:
	_hud.update_objective(index, current, required)


## The whole 5-step chain lives in this one table: task -> what unlocks next.
const NEXT_TASK: Dictionary = {
	&"move_to_point": &"get_weapon",
	&"get_weapon": &"eliminate_mutants",
	&"eliminate_mutants": &"defeat_boss",
	&"defeat_boss": &"end_level",
	&"end_level": &"", # end of chain — nothing to activate next
}

func _on_task_completed(task_id: StringName) -> void:
	_hud.hide_task()
	for marker: Sprite2D in QUEST_MARKERS.get(task_id, []):
		if is_instance_valid(marker):
			marker.visible = false
	var next_id: StringName = NEXT_TASK.get(task_id, &"")
	if next_id != &"":
		_progress.activate(next_id)


# ── Death / Game Over ──
# Same dual-hosting handling as OutskirtLevel/DowntownLevel: works whether
# this level is hosted inside StateManager's PlayingState or run directly as
# the current scene.

func _on_player_died() -> void:
	await get_tree().create_timer(2.0).timeout

	var level: PackedScene = load(scene_file_path)
	if _host_is_playing_state():
		StateManager.push_state("game_over", {"level": level})
	else:
		var overlay: GameOver = (load("res://scenes/ui/GameOver.tscn") as PackedScene).instantiate()
		add_child(overlay)
		overlay.state_enter({"level": level, "standalone": true})


func _host_is_playing_state() -> bool:
	var p: Node = get_parent()
	while p != null:
		if p.has_method("state_enter") and p.name == "PlayingState":
			return true
		p = p.get_parent()
	return false
