extends Node2D
class_name OutskirtLevel
## Level script for Outskirt. Defines the 8-step story task chain and wires
## dialogue to task completion, area approach, and item pickup.

@onready var _progress: TaskManager = $TaskManager
@onready var _hud: HUD = $HUD
@onready var _dialogue: DialogueBox = $DialogueBox   

@onready var _destination_area: Area2D = $QuestRelated/DestinationMarker
@onready var _weapon_pickup: Interactable = $QuestRelated/WeaponPickup/Interactable
@onready var _gate_area: Area2D = $QuestRelated/Gate/Area2D            # proximity detection (steps 4 & 6)
@onready var _generator: Interactable = $QuestRelated/Generator/Interactable
@onready var _pin_pickup: Interactable = $QuestRelated/PinPickup/Interactable
@onready var _gate_open: Interactable = $QuestRelated/Gate/Interactable  # the actual "open" action (step 8)

@onready var _walls_tile_layer: TileMapLayer = $TileMapLayers/Walls

const ZOMBIE_SCENE: PackedScene = preload("res://scenes/entities/ZombieAxe.tscn")

func _ready() -> void:
	_define_tasks()
	_connect_enemies()
	_connect_triggers()
	_connect_task_signals()
	_progress.activate("move_to_point")   # first task in the chain


func _define_tasks() -> void:
	_register_task("move_to_point", "Move to the destination", TaskObjective.Type.REACH, "waypoint", 1, [])
	_register_task("get_weapon", "Pick up a weapon", TaskObjective.Type.COLLECT, "weapon", 1, ["move_to_point"])
	_register_task("eliminate_mutants", "Eliminate the mutants", TaskObjective.Type.KILL, "mutant", 3, ["get_weapon"])
	_register_task("find_gate", "Find the locked iron gate", TaskObjective.Type.REACH, "iron_gate", 1, ["eliminate_mutants"])
	_register_task("activate_power", "Activate the power", TaskObjective.Type.CUSTOM, "generator", 1, ["find_gate"])
	_register_task("return_to_gate", "Return to the iron gate", TaskObjective.Type.REACH, "iron_gate", 1, ["activate_power"])
	_register_task("find_pin", "Find the keypad PIN", TaskObjective.Type.COLLECT, "pin", 1, ["return_to_gate"])
	_register_task("open_gate", "Open the iron gate", TaskObjective.Type.CUSTOM, "iron_gate", 1, ["find_pin"])


## Small helper so the 8-task chain above isn't 80 lines of repeated boilerplate.
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


func _connect_enemies() -> void:
	for zombie: ZombieAxe in get_tree().get_nodes_in_group("enemies"):
		if not zombie.died.is_connected(_on_mutant_died):
			zombie.died.connect(_on_mutant_died)

func _spawn_mutant(at_position: Vector2) -> void:
	var zombie: ZombieAxe = ZOMBIE_SCENE.instantiate()
	zombie.position = at_position
	$Monsters.add_child(zombie)
	zombie.died.connect(_on_mutant_died)   # must connect manually — _connect_enemies() only runs once at _ready()

func _change_gate_tiles() -> void:
	_walls_tile_layer.set_cell(Vector2i(79, 11), 0, Vector2i(2, 1))
	_walls_tile_layer.set_cell(Vector2i(79, 10), 0, Vector2i(2, 0))
	_walls_tile_layer.set_cell(Vector2i(81, 11), 0, Vector2i(3, 1))
	_walls_tile_layer.set_cell(Vector2i(81, 10), 0, Vector2i(3, 0))
	
	_walls_tile_layer.erase_cell(Vector2i(80, 11))

## Wires every physical trigger in the level to its matching task step.
## This is the part that has no reusable pattern to copy — build once here.
func _connect_triggers() -> void:
	_destination_area.body_entered.connect(_on_destination_reached)
	_weapon_pickup.interacted.connect(_on_weapon_picked_up)
	_gate_area.body_entered.connect(_on_gate_area_entered)
	_generator.interacted.connect(_on_generator_activated)
	_pin_pickup.interacted.connect(_on_pin_picked_up)
	_gate_open.interacted.connect(_on_gate_open_attempted)


# ── Trigger callbacks: advance the task AND show the matching dialogue line ──

func _on_destination_reached(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not _progress.is_active("move_to_point"):
		return   # already triggered — ignore repeat visits
	_progress.advance("move_to_point", 0, 1)
	_dialogue.show_monologue("This looks like the spot.")
	_destination_area.set_deferred("monitoring", false)


func _on_weapon_picked_up(_interactor: Node2D) -> void:
	_progress.advance("get_weapon", 0, 1)
	_dialogue.show_monologue("Picked up a weapon. Better than nothing.")


func _on_mutant_died() -> void:
	var was_active: bool = _progress.is_active("eliminate_mutants")
	_progress.advance("eliminate_mutants", 0, 1)
	if was_active and _progress.is_completed("eliminate_mutants"):
		_dialogue.show_monologue("That's the last of them... for now.")


func _on_gate_area_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	var was_finding_gate: bool = _progress.is_active("find_gate")
	var was_returning: bool = _progress.is_active("return_to_gate")
	
	_progress.advance("find_gate", 0, 1)
	_progress.advance("return_to_gate", 0, 1)
	
	if was_finding_gate:
		_dialogue.show_monologue("A locked iron gate. I need another way through.")
	elif was_returning:
		_dialogue.show_monologue("Back at the gate. Still need to get it open.")


func _on_generator_activated(_interactor: Node2D) -> void:
	_progress.advance("activate_power", 0, 1)
	_dialogue.show_monologue("Power's back on. Time to head back.")


func _on_pin_picked_up(_interactor: Node2D) -> void:
	_progress.advance("find_pin", 0, 1)
	_dialogue.show_monologue("Found a PIN. This should open the gate.")
	_spawn_mutant(Vector2(2500, randf_range(1250, 1500)))
	_spawn_mutant(Vector2(2500, randf_range(1250, 1500)))
	_spawn_mutant(Vector2(2750, randf_range(1250, 1500)))
	_spawn_mutant(Vector2(3050, randf_range(1250, 1500)))
	_spawn_mutant(Vector2(3050, randf_range(1250, 1500)))


func _on_gate_open_attempted(_interactor: Node2D) -> void:
	# Guard against the player pressing E on the gate before "open_gate" is
	# actually the active task — give feedback instead of silently failing.
	if not _progress.is_active("open_gate"):
		_dialogue.show_monologue("It's still locked.")
		return
	_progress.advance("open_gate", 0, 1)
	_dialogue.show_monologue("Gate's open. Let's move.")
	
	# open the gate
	_change_gate_tiles()


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


func _on_objective_advanced(_task_id: StringName, index: int, current: int, required: int) -> void:
	_hud.update_objective(index, current, required)


## The whole 8-step chain lives in this one table: task -> what unlocks next.
## Add/reorder tasks here instead of hunting through scattered if-statements.
const NEXT_TASK: Dictionary = {
	&"move_to_point": &"get_weapon",
	&"get_weapon": &"eliminate_mutants",
	&"eliminate_mutants": &"find_gate",
	&"find_gate": &"activate_power",
	&"activate_power": &"return_to_gate",
	&"return_to_gate": &"find_pin",
	&"find_pin": &"open_gate",
	&"open_gate": &"",   # end of chain — nothing to activate next
}

func _on_task_completed(task_id: StringName) -> void:
	_hud.hide_task()
	var next_id: StringName = NEXT_TASK.get(task_id, &"")
	if next_id != &"":
		_progress.activate(next_id)
