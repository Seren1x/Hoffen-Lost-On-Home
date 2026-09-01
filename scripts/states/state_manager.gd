## Autoload singleton. Add this script as an Autoload named "StateManager"
## in Project Settings > Autoload.
##
## Two ways to switch states:
##   change_state("playing")           - replaces the ENTIRE stack (menu -> playing)
##   push_state("paused")              - stacks on top, keeps what's below alive (playing -> paused)
##   pop_state()                       - removes the top state, resumes what's below
extends Node

## Register every state scene here. Preloading means switching states
## never causes a disk-load hitch mid-game.
const STATE_SCENES: Dictionary = {
	"main_menu": preload("res://scenes/ui/MainMenu.tscn"),
	"playing": preload("res://scenes/states/PlayingState.tscn"),
	"paused": preload("res://scenes/ui/PauseMenu.tscn"),
	"settings": preload("res://scenes/ui/SettingsMenu.tscn"),
	"game_over": preload("res://scenes/ui/GameOver.tscn"),
	"demo_task": preload("res://scenes/demo/DemoTask.tscn")
}

var _stack: Array[Node] = []   # was: Array[GameState]


func _ready() -> void:
	# First state the game boots into. Change this if you want to skip
	# straight to "playing" while testing.
	change_state("main_menu")


func current_state() -> Node:   # was: -> GameState
	return _stack[-1] if not _stack.is_empty() else null


## Tears down every state currently on the stack and starts fresh with
## a single new one. Use for hard transitions: MainMenu -> Playing,
## Playing -> GameOver.
func change_state(state_name: String, data: Dictionary = {}) -> void:
	while not _stack.is_empty():
		_pop_internal()
	_push_internal(state_name, data)


## Adds a new state on top of the stack WITHOUT removing what's below.
## The state underneath gets frozen (process_mode disabled) but stays
## instantiated in memory, so its data/scene tree is untouched.
## Use for: Playing -> Paused, Playing -> InventoryMenu, etc.
func push_state(state_name: String, data: Dictionary = {}) -> void:
	var below := current_state()
	if below:
		below.process_mode = Node.PROCESS_MODE_DISABLED
		# If the state below is itself an overlay (e.g. Settings pushed on top of
		# Pause), hide it so the two UIs don't draw over each other. World states
		# (PlayingState) stay visible behind overlays so the frozen game world is
		# still shown behind the pause menu.
		if not _is_world_state(below):
			_set_state_visible(below, false)
	_push_internal(state_name, data)


## Removes the top state and resumes whatever is now on top.
## Use for: Paused -> Playing (i.e. "resume").
func pop_state() -> void:
	if _stack.is_empty():
		push_warning("StateManager: pop_state() called with empty stack")
		return
	_pop_internal()
	var below := current_state()
	if below:
		below.process_mode = Node.PROCESS_MODE_INHERIT
		if not _is_world_state(below):
			_set_state_visible(below, true)


func _push_internal(state_name: String, data: Dictionary) -> void:
	var scene: PackedScene = STATE_SCENES.get(state_name)
	if scene == null:
		push_error("StateManager: unknown state '%s'" % state_name)
		return
	var instance: Node = scene.instantiate()   # was: GameState
	add_child(instance)
	_stack.push_back(instance)
	if instance.has_method("state_enter"):     # new guard
		instance.state_enter(data)


func _pop_internal() -> void:
	var top: Node = _stack.pop_back()          # was: GameState
	if top.has_method("state_exit"):           # new guard
		top.state_exit()
	top.queue_free()


## A "world" state renders a live scene (the playing level) and should stay
## visible behind overlay states. Overlay states (menus/pause/settings) return
## false, so they are hidden while another overlay is stacked on top of them.
func _is_world_state(node: Node) -> bool:
	if node.has_method("is_world_state"):
		return node.is_world_state()
	return false


## Toggles visibility of a state's root node. All state roots in this project
## are CanvasItems (Control/Node2D) or CanvasLayers, both of which expose
## `visible`.
func _set_state_visible(node: Node, value: bool) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = value
	elif node is CanvasItem:
		(node as CanvasItem).visible = value
