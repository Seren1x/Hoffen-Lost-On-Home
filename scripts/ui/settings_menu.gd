extends CanvasLayer
class_name SettingsMenu

@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheck


func _ready() -> void:
	# Render/process on top of everything (including the game world below),
	# so the Settings screen always covers the level and its collision debug.
	process_mode = Node.PROCESS_MODE_ALWAYS
	%BackButton.pressed.connect(_on_back_pressed)
	_volume_slider.max_value = 1.0
	_volume_slider.value = SettingsManager.master_volume
	_volume_slider.value_changed.connect(_on_volume_changed)
	_fullscreen_check.button_pressed = SettingsManager.fullscreen
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)


func _on_back_pressed() -> void:
	StateManager.pop_state()


# ── Master volume ──

func _on_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)


# ── Fullscreen ──

func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)
