extends Control
class_name MainMenu

@export var game_scene: PackedScene

func _ready() -> void:
	%StartButton.pressed.connect(_on_start_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)

func _on_settings_pressed() -> void:
	# Placeholder for settings
	pass

func _on_exit_pressed() -> void:
	get_tree().quit()
