extends Control
class_name MainMenu

@export var game_scene: PackedScene
@export var settings_scene: PackedScene

func _ready() -> void:
	%StartButton.pressed.connect(_on_start_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)

func _on_settings_pressed() -> void:
	if not settings_scene:
		return
	var settings: Control = settings_scene.instantiate()
	settings.back_pressed.connect(_on_settings_closed.bind(settings))
	add_child(settings)

func _on_settings_closed(settings: Control) -> void:
	settings.queue_free()

func _on_exit_pressed() -> void:
	get_tree().quit()
