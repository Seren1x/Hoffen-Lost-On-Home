extends Node2D
class_name TestOutskirtLevel
## Test level for Outskirt. Same gameplay as the real level, but with
## easier task requirements so you can quickly verify the task system.
## (Chapter 1 needs only 1 zombie, and Chapter 2 is auto-activated.)

@onready var _progress: TaskManager = $TaskManager
@onready var _hud: HUD = $HUD
@onready var _dialogue: DialogueBox = $DialogueBox
@onready var _fog: FogOverlay = $FogOverlay
@onready var _player: CharacterBody2D = $YSortEntities/Player


func _ready() -> void:
	# Demo: a tighter, stronger vignette than the defaults.
	_fog.set_fog(0.5, 0.4, 0.85)
	_define_tasks()
	_connect_enemies()
	_connect_task_signals()
	_progress.activate("escape_forest")
	# For testing: also start chapter 2 right away so you can see multiple tasks.
	_progress.activate("find_shelter")
	# Show a demo dialogue so you can see the component.
	_dialogue.show_lines([
		{"speaker": "Rain", "text": "Welcome to the test level! Press Space to advance."},
		{"text": "This is a monologue line with no speaker name."},
	])
	_player.player_died.connect(_on_player_died)


func _define_tasks() -> void:
	# ── Chapter 1: Escape the Forest (easy: 1 zombie) ──
	var ch1 := TaskData.new()
	ch1.id = "escape_forest"
	ch1.title = "Escape the Forest"
	ch1.description = "TEST: Defeat just 1 zombie to complete."

	var kill_zombies := TaskObjective.new()
	kill_zombies.type = TaskObjective.Type.KILL
	kill_zombies.description = "Defeat zombies"
	kill_zombies.target_id = "zombie"
	kill_zombies.required = 1
	ch1.objectives.append(kill_zombies)

	_progress.register(ch1)

	# ── Chapter 2: Find Shelter (auto-active for testing) ──
	var ch2 := TaskData.new()
	ch2.id = "find_shelter"
	ch2.title = "Find Shelter"
	ch2.description = "Locate a safe place before nightfall."

	var reach_shelter := TaskObjective.new()
	reach_shelter.type = TaskObjective.Type.REACH
	reach_shelter.description = "Reach the abandoned cabin"
	reach_shelter.target_id = "cabin"
	reach_shelter.required = 1
	ch2.objectives.append(reach_shelter)

	_progress.register(ch2)


func _connect_enemies() -> void:
	for zombie: Enemy in get_tree().get_nodes_in_group("enemies"):
		if not zombie.died.is_connected(_on_zombie_died):
			zombie.died.connect(_on_zombie_died)


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


# ── Death / Game Over ──
# The game-over overlay is handled differently depending on how this level is
# hosted, so Restart and Quit behave correctly in both cases:
#   * Through the StateManager's PlayingState (menu -> playing): push the
#     GameOver state and let change_state() rebuild the playing stack.
#   * Run directly as the current scene (e.g. pressing Play on this scene):
#     instance the GameOver overlay as a child of THIS level, because there is
#     no PlayingState above us for change_state() to replace.

func _on_player_died() -> void:
	# Give the death animation a moment to play before showing the overlay.
	await get_tree().create_timer(2.0).timeout

	var level: PackedScene = load(scene_file_path)
	if _host_is_playing_state():
		StateManager.push_state("game_over", {"level": level})
	else:
		var overlay: GameOver = (load("res://scenes/ui/GameOver.tscn") as PackedScene).instantiate()
		add_child(overlay)
		overlay.state_enter({"level": level, "standalone": true})


## True when this level is hosted inside the StateManager's PlayingState
## (i.e. it was launched through the main menu), False when it is being run
## directly as the current scene.
func _host_is_playing_state() -> bool:
	var p: Node = get_parent()
	while p != null:
		if p.has_method("state_enter") and p.name == "PlayingState":
			return true
		p = p.get_parent()
	return false
