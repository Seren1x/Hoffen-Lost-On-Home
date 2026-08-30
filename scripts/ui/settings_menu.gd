extends Control
class_name SettingsMenu

signal back_pressed

const MASTER_BUS := 0  ## index of the "Master" audio bus

@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheck


func _ready() -> void:
	%BackButton.pressed.connect(_on_back_pressed)
	_volume_slider.max_value = 1.0
	_volume_slider.value = _get_master_volume()
	_volume_slider.value_changed.connect(_on_volume_changed)
	_fullscreen_check.button_pressed = _is_fullscreen()
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)


func _on_back_pressed() -> void:
	back_pressed.emit()


# ── Master volume ──

func _get_master_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(MASTER_BUS))


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(value))
	AudioServer.set_bus_mute(MASTER_BUS, value <= 0.0)


# ── Fullscreen ──

func _is_fullscreen() -> bool:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)
