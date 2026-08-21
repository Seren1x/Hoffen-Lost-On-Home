extends CanvasLayer
class_name PauseMenu

@export var settings_scene: PackedScene

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	hide()
	%ResumeButton.pressed.connect(_on_resume_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%ExitToMainButton.pressed.connect(_on_quit_to_menu_pressed)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	if event.pressed and event.keycode == KEY_ESCAPE:
		if visible:
			_resume()
		else:
			_pause()

func _pause() -> void:
	get_tree().paused = true
	show()

func _resume() -> void:
	get_tree().paused = false
	hide()

func _on_resume_pressed() -> void:
	_resume()

func _on_settings_pressed() -> void:
	if not settings_scene:
		return
	var settings: Control = settings_scene.instantiate()
	settings.back_pressed.connect(_on_settings_closed.bind(settings))
	add_child(settings)

func _on_settings_closed(settings: Control) -> void:
	settings.queue_free()

func _on_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(&"res://scenes/ui/MainMenu.tscn")
