extends Control
class_name SettingsMenu

signal back_pressed

func _ready() -> void:
	%BackButton.pressed.connect(_on_back_pressed)
	%FullscreenCheck.button_pressed = _is_fullscreen()

func _on_back_pressed() -> void:
	back_pressed.emit()

func _is_fullscreen() -> bool:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
