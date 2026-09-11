extends ColorRect
## Final "Thanks for playing" screen shown after the last level.
## Plays an ending video, then returns to the main menu when it finishes.
## If no video is assigned, falls back to a timed delay instead.
## Any key press / click / tap skips straight to the main menu.

## Assign an .ogv (Ogg Theora) VideoStream here in the Inspector.
@export var video: VideoStream

## Used only as a fallback if no video is assigned.
@export var auto_return_delay: float = 6.0

var _returning: bool = false

@onready var _video_player: VideoStreamPlayer = $VideoStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if video:
		_video_player.stream = video
		_video_player.finished.connect(_return_to_menu)
		_video_player.play()
	else:
		_video_player.hide()
		get_tree().create_timer(auto_return_delay).timeout.connect(_return_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	var is_press: bool = (
		(event is InputEventKey and event.pressed)
		or (event is InputEventMouseButton and event.pressed)
		or (event is InputEventScreenTouch and event.pressed)
	)
	if is_press:
		_return_to_menu()


func _return_to_menu() -> void:
	if _returning:
		return
	_returning = true
	StateManager.change_state("main_menu")
