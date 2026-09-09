extends Node2D
class_name DowntownLevel
## Level script for Downtown. Defines the 12-step story task chain and wires
## dialogue to task completion, area approach, and item pickup.
## Mirrors OutskirtLevel's architecture (TaskManager/TaskData/TaskObjective + HUD + DialogueBox).

@onready var _progress: TaskManager = $TaskManager
@onready var _hud: HUD = $HUD
@onready var _dialogue: DialogueBox = $DialogueBox

@onready var _player: CharacterBody2D = $YSortEntities/Player

@onready var _destination_area: Area2D = $QuestRelated/DestinationMarker

@onready var _gate1_area: Area2D = $QuestRelated/GateNoOne/Area2D
@onready var _gate1_open: Interactable = $QuestRelated/GateNoOne/Interactable
@onready var _key_pickup: Interactable = $QuestRelated/KeyPickup/Interactable

@onready var _gate2_area: Area2D = $QuestRelated/GateNoTwo/Area2D
@onready var _gate2_open: Interactable = $QuestRelated/GateNoTwo/Interactable
@onready var _fragment_pickups: Array[Interactable] = [
	$QuestRelated/FragmentPickup/KeyPickup/Interactable,
	$QuestRelated/FragmentPickup/KeyPickup2/Interactable,
	$QuestRelated/FragmentPickup/KeyPickup3/Interactable,
]

@onready var _vehicle_area: Area2D = $QuestRelated/Vehicle/Area2D
@onready var _gasoline_pickup: Interactable = $QuestRelated/GasolinePickup/Interactable

@onready var _walls_tile_layer: TileMapLayer = $TileMapLayers/Walls

const SPEAKER_NAME := "Rain"   # change if Downtown is a different POV character
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/entities/ZombieAxe.tscn")

@onready var QUEST_MARKERS: Dictionary = {
	"move_to_point": [$QuestRelated/DestinationMarker/Marker],
	"explore_gate1": [$QuestRelated/GateNoOne/Area2D/Marker],
	"find_key": [$QuestRelated/KeyPickup/Marker],
	"open_gate1": [$QuestRelated/GateNoOne/Interactable/Marker],
	"explore_gate2": [$QuestRelated/GateNoTwo/Area2D/Marker],
	"open_gate2": [$QuestRelated/GateNoTwo/Interactable/Marker],
	"find_fragments": [
		$QuestRelated/FragmentPickup/KeyPickup/Marker,
		$QuestRelated/FragmentPickup/KeyPickup2/Marker,
		$QuestRelated/FragmentPickup/KeyPickup3/Marker,
	],
	"search_vehicle": [$QuestRelated/Vehicle/Marker],
	"find_gasoline": [$QuestRelated/GasolinePickup/Marker],
	"escape_vehicle": [$QuestRelated/Vehicle/Marker],
}

func _ready() -> void:
	_define_tasks()
	_connect_triggers()
	_connect_task_signals()
	_hide_all_markers()
	_progress.activate("move_to_point")   # first task in the chain
	_player.player_died.connect(_on_player_died)


func _define_tasks() -> void:
	_register_task("move_to_point", "Go to the destination", TaskObjective.Type.REACH, "waypoint", 1, [])
	_register_task("explore_gate1", "Explore the area near Gate #1", TaskObjective.Type.REACH, "gate_one", 1, ["move_to_point"])
	_register_task("find_key", "Find the key", TaskObjective.Type.COLLECT, "key", 1, ["explore_gate1"])
	_register_task("eliminate_horde1", "Fight off the zombie horde", TaskObjective.Type.KILL, "zombie", 5, ["find_key"])
	_register_task("open_gate1", "Open Gate #1", TaskObjective.Type.CUSTOM, "gate_one", 1, ["eliminate_horde1"])
	_register_task("explore_gate2", "Explore the area near Gate #2", TaskObjective.Type.REACH, "gate_two", 1, ["open_gate1"])
	_register_task("find_fragments", "Find the lever fragments", TaskObjective.Type.COLLECT, "fragment", 3, ["explore_gate2"])
	_register_task("open_gate2", "Open Gate #2", TaskObjective.Type.CUSTOM, "gate_two", 1, ["find_fragments"])
	_register_task("search_vehicle", "Search the vehicle", TaskObjective.Type.REACH, "vehicle", 1, ["open_gate2"])
	_register_task("find_gasoline", "Find gas fuel", TaskObjective.Type.COLLECT, "gasoline", 1, ["search_vehicle"])
	_register_task("eliminate_horde2", "Fight off the zombie horde", TaskObjective.Type.KILL, "zombie", 8, ["find_gasoline"])
	_register_task("escape_vehicle", "Get back to the vehicle", TaskObjective.Type.REACH, "vehicle", 1, ["eliminate_horde2"])


## Small helper so the 12-task chain above isn't 100+ lines of repeated boilerplate.
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


func _spawn_horde(count: int, center: Vector2, spread: float) -> void:
	for i in range(count):
		var offset := Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
		var zombie: ZombieAxe = ZOMBIE_SCENE.instantiate()
		zombie.position = center + offset
		$YSortEntities/Monsters.add_child(zombie)
		zombie.died.connect(_on_horde_zombie_died)


func _change_gate1_tiles() -> void:
	
	var alt_180 = TileSetAtlasSource.TRANSFORM_FLIP_V
	
	_walls_tile_layer.set_cell(Vector2i(41, 17), 0, Vector2i(2, 1), alt_180)
	_walls_tile_layer.set_cell(Vector2i(41, 18), 0, Vector2i(2, 0), alt_180)
	_walls_tile_layer.set_cell(Vector2i(43, 17), 0, Vector2i(3, 1), alt_180)
	_walls_tile_layer.set_cell(Vector2i(43, 18), 0, Vector2i(3, 0), alt_180)
	
	_walls_tile_layer.erase_cell(Vector2i(42, 17))


func _change_gate2_tiles() -> void:
	_walls_tile_layer.set_cell(Vector2i(71, 17), 0, Vector2i(2, 1))
	_walls_tile_layer.set_cell(Vector2i(71, 16), 0, Vector2i(2, 0))
	_walls_tile_layer.set_cell(Vector2i(73, 17), 0, Vector2i(3, 1))
	_walls_tile_layer.set_cell(Vector2i(73, 16), 0, Vector2i(3, 0))
	
	_walls_tile_layer.erase_cell(Vector2i(72, 17))


func _hide_all_markers() -> void:
	for markers: Array in QUEST_MARKERS.values():
		for marker in markers:
			if is_instance_valid(marker):
				marker.visible = false

## Wires every physical trigger in the level to its matching task step.
func _connect_triggers() -> void:
	_destination_area.body_entered.connect(_on_destination_reached)
	_gate1_area.body_entered.connect(_on_gate1_area_entered)
	_gate1_open.interacted.connect(_on_gate1_open_attempted)
	_key_pickup.interacted.connect(_on_key_picked_up)
	_gate2_area.body_entered.connect(_on_gate2_area_entered)
	_gate2_open.interacted.connect(_on_gate2_open_attempted)
	for fragment: Interactable in _fragment_pickups:
		fragment.interacted.connect(_on_fragment_picked_up.bind(fragment))
	_vehicle_area.body_entered.connect(_on_vehicle_area_entered)
	_gasoline_pickup.interacted.connect(_on_gasoline_picked_up)


# ── Trigger callbacks: advance the task AND show the matching dialogue line ──

func _on_destination_reached(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not _progress.is_active("move_to_point"):
		return
	_progress.advance("move_to_point", 0, 1)
	_dialogue.show_dialogue(SPEAKER_NAME, "This is the place. Let's take a look around.")
	_destination_area.set_deferred("monitoring", false)


func _on_gate1_area_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not _progress.is_active("explore_gate1"):
		return
	_progress.advance("explore_gate1", 0, 1)
	_dialogue.show_dialogue(SPEAKER_NAME, "A gate, locked tight. I'll need a key — and it sounds like company's coming.")


func _on_key_picked_up(_interactor: Node2D) -> void:
	_progress.advance("find_key", 0, 1)
	_dialogue.show_dialogue(SPEAKER_NAME, "Got the key. Now I just have to survive long enough to use it.")
	_spawn_horde(5, _gate1_area.global_position, 120.0)


func _on_horde_zombie_died() -> void:
	if _progress.is_active("eliminate_horde1"):
		_progress.advance("eliminate_horde1", 0, 1)
		if _progress.is_completed("eliminate_horde1"):
			_dialogue.show_dialogue(SPEAKER_NAME, "That's the last of them. Gate's mine now.")
	elif _progress.is_active("eliminate_horde2"):
		_progress.advance("eliminate_horde2", 0, 1)
		if _progress.is_completed("eliminate_horde2"):
			_dialogue.show_dialogue(SPEAKER_NAME, "Down! Get to the car, now!")


func _on_gate2_area_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not _progress.is_active("explore_gate2"):
		return
	_progress.advance("explore_gate2", 0, 1)
	_dialogue.show_dialogue(SPEAKER_NAME, "Second gate. This one needs some kind of lever — looks broken apart.")


## Guard against the player pressing E before "open_gate1" is the active
## task — give feedback instead of silently failing. Same shape as
## OutskirtLevel's single gate handler.
func _on_gate1_open_attempted(_interactor: Node2D) -> void:
	if not _progress.is_active("open_gate1"):
		_dialogue.show_dialogue(SPEAKER_NAME, "It won't budge. Something's still stopping it.")
		return
	_progress.advance("open_gate1", 0, 1)
	_dialogue.show_dialogue(SPEAKER_NAME, "Gate #1's open. Keep moving.")
	_change_gate1_tiles()


func _on_gate2_open_attempted(_interactor: Node2D) -> void:
	if not _progress.is_active("open_gate2"):
		_dialogue.show_dialogue(SPEAKER_NAME, "It won't budge. Something's still stopping it.")
		return
	_progress.advance("open_gate2", 0, 1)
	_dialogue.show_dialogue(SPEAKER_NAME, "Gate #2's open. The car's close now.")
	_change_gate2_tiles()


func _on_fragment_picked_up(_interactor: Node2D, fragment: Interactable) -> void:
	if not _progress.is_active("find_fragments"):
		return
	_progress.advance("find_fragments", 0, 1)
	fragment.get_parent().queue_free()
	if _progress.is_completed("find_fragments"):
		_dialogue.show_dialogue(SPEAKER_NAME, "That's all the pieces. Let's put this lever back together.")
	else:
		_dialogue.show_dialogue(SPEAKER_NAME, "One more fragment down. A couple left.")


func _on_vehicle_area_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if _progress.is_active("search_vehicle"):
		_progress.advance("search_vehicle", 0, 1)
		_dialogue.show_dialogue(SPEAKER_NAME, "Empty tank. I need to find fuel before this thing goes anywhere.")
	elif _progress.is_active("escape_vehicle"):
		_progress.advance("escape_vehicle", 0, 1)
		_dialogue.show_monologue("Level end")
		StateManager.change_state("win_screen")


func _on_gasoline_picked_up(_interactor: Node2D) -> void:
	_progress.advance("find_gasoline", 0, 1)
	_dialogue.show_dialogue(SPEAKER_NAME, "Fuel. Now let's make some noise and get out of here.")
	_spawn_horde(8, _vehicle_area.global_position, 170.0)


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
	for marker in QUEST_MARKERS.get(task_id, []):
		if is_instance_valid(marker):
			marker.visible = true


func _on_objective_advanced(_task_id: StringName, index: int, current: int, required: int) -> void:
	_hud.update_objective(index, current, required)


## The whole 12-step chain lives in this one table: task -> what unlocks next.
const NEXT_TASK: Dictionary = {
	&"move_to_point": &"explore_gate1",
	&"explore_gate1": &"find_key",
	&"find_key": &"eliminate_horde1",
	&"eliminate_horde1": &"open_gate1",
	&"open_gate1": &"explore_gate2",
	&"explore_gate2": &"find_fragments",
	&"find_fragments": &"open_gate2",
	&"open_gate2": &"search_vehicle",
	&"search_vehicle": &"find_gasoline",
	&"find_gasoline": &"eliminate_horde2",
	&"eliminate_horde2": &"escape_vehicle",
	&"escape_vehicle": &"", # end of chain — nothing to activate next
}

func _on_task_completed(task_id: StringName) -> void:
	_hud.hide_task()
	for marker in QUEST_MARKERS.get(task_id, []):
		if is_instance_valid(marker):
			marker.visible = false
	var next_id: StringName = NEXT_TASK.get(task_id, &"")
	if next_id != &"":
		_progress.activate(next_id)


# ── Death / Game Over ──
# Same dual-hosting handling as OutskirtLevel: works whether this level is
# hosted inside StateManager's PlayingState or run directly as the current scene.

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
