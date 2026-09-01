extends CanvasLayer
class_name GameOver
## Reusable game-over overlay.
##
## Two ways to use it:
##   * Hosted by the StateManager (menu -> PlayingState): pushed via
##     StateManager.push_state("game_over", {"level": <PackedScene>}).
##     Restart calls change_state("playing", {level}) which tears down the old
##     playing/game-over states and boots a fresh level. Quit -> main menu.
##   * Standalone (level run directly as the current scene, e.g. pressing Play
##     on the level scene): instance it as a child of the level and call
##     state_enter({"level": <PackedScene>, "standalone": true}). In this mode
##     there is no state stack to rebuild, so Restart reloads the current scene
##     and Quit shows the menu managed by StateManager after freeing the level.
##
## Works with any level — the scene to reload is passed in via the data, so
## this node has no hardcoded level path.

var _level_scene: PackedScene = null
## When true, this overlay was instanced directly onto a level that is running
## as the current scene (not hosted by the StateManager's PlayingState). In that
## mode there is no state stack to rebuild, so Restart reloads the scene and
## Quit falls back to loading the main menu scene directly.
var _standalone: bool = false

@onready var _root: Control = $Root
@onready var _restart_button: Button = %RestartButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	# Must keep responding to input even though the PlayingState below is frozen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


## Called by StateManager when this state is pushed (or directly by a level when
## running standalone). Receives the level that was being played so Restart can
## reload the exact same scene.
func state_enter(data: Dictionary = {}) -> void:
	_level_scene = data.get("level", null) as PackedScene
	_standalone = data.get("standalone", false)
	_root.show()


func _on_restart_pressed() -> void:
	if _standalone:
		# Running as the current scene: no state stack above us, so reload the
		# whole scene fresh (new level, new player at the spawn point).
		get_tree().reload_current_scene()
		return
	var level: PackedScene = _level_scene
	# Fully tear down the old playing/game-over states and boot a fresh level.
	StateManager.change_state("playing", {"level": level} if level else {})


func _on_quit_pressed() -> void:
	if _standalone:
		# Running as the current scene: free this level so the menu (managed by
		# StateManager) is actually visible instead of being drawn underneath it.
		StateManager.change_state("main_menu")
		var sc := get_tree().current_scene
		if sc != null and sc != get_tree().root:
			sc.queue_free()
		return
	StateManager.change_state("main_menu")
