extends CanvasLayer
class_name PauseMenu

@export var settings_scene: PackedScene

var _hud: HUD

@onready var _stats_panel: VBoxContainer = %StatsPanel
@onready var _hp_label: Label = %HPLabel
@onready var _energy_label: Label = %EnergyLabel


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	hide()
	_hud = _find_hud()
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


func _find_hud() -> HUD:
	var parent: Node = get_parent()
	if parent:
		return parent.get_node_or_null("HUD") as HUD
	return null


func _pause() -> void:
	get_tree().paused = true
	if _hud:
		_hud.hide()
		_refresh_stats()
	show()


func _resume() -> void:
	get_tree().paused = false
	if _hud:
		_hud.show()
	hide()


func _refresh_stats() -> void:
	if not _hud:
		return
	_hp_label.text = "HP: %d / %d" % [int(_hud.hp_bar.value), int(_hud.hp_bar.max_value)]
	_energy_label.text = "Energy: %d / %d" % [int(_hud.energy_bar.value), int(_hud.energy_bar.max_value)]
	_stats_panel.show()


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
