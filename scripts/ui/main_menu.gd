extends Control
class_name MainMenuState

func _ready() -> void:
	%StartButton.pressed.connect(_on_start_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%ExitButton.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	StateManager.change_state("playing")

func _on_settings_pressed() -> void:
	StateManager.push_state("settings")   # overlay, same pattern as pause

func _on_exit_pressed() -> void:
	get_tree().quit()
