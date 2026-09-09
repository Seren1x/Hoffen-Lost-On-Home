extends CanvasLayer
class_name PauseMenu

## Adjustable panels (drag them in the editor to reposition/resize).
@onready var _health_panel: PanelContainer = %HealthPanel
@onready var _energy_panel: PanelContainer = %EnergyPanel
@onready var _weapon_panel: PanelContainer = %WeaponPanel
@onready var _objective_panel: PanelContainer = %ObjectivePanel
@onready var _health_label: Label = %HealthLabel
@onready var _energy_label: Label = %EnergyLabel
@onready var _weapon_label: Label = %WeaponLabel
@onready var _objective_title: Label = %ObjectiveTitle
@onready var _objective_label: Label = %ObjectiveLabel

## Whether the HUD was visible before we hid it, so we can restore it on resume.
var _hud_was_visible: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%ResumeButton.pressed.connect(_on_resume_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%ExitToMainButton.pressed.connect(_on_quit_to_menu_pressed)


func state_enter(data: Dictionary = {}) -> void:
	# Hide the gameplay HUD while paused — its info is shown here instead.
	_hide_hud()

	# Health
	_health_panel.visible = data.has("hp")
	if data.has("hp"):
		_health_label.text = "HP: %d / %d" % [int(data.hp), int(data.max_hp)]

	# Energy / stamina
	_energy_panel.visible = data.has("energy")
	if data.has("energy"):
		_energy_label.text = "Energy: %d / %d" % [int(data.energy), int(data.max_energy)]

	# Weapon
	_weapon_panel.visible = data.has("weapon_name")
	if data.has("weapon_name"):
		_weapon_label.text = "%s  %d/%d" % [
			data.weapon_name, int(data.weapon_ammo), int(data.weapon_max_ammo)]

	# Objective
	_show_objective(data)


func state_exit() -> void:
	_show_hud()


func _show_objective(data: Dictionary) -> void:
	_objective_panel.visible = data.has("task_title")
	if not data.has("task_title"):
		return
	_objective_title.text = data.task_title
	var lines: Array[String] = []
	for obj: Dictionary in data.get("task_objectives", []):
		lines.append("  %s  %d/%d" % [obj.description, int(obj.current), int(obj.required)])
	_objective_label.text = "\n".join(lines) if not lines.is_empty() else ""


func _hide_hud() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		_hud_was_visible = hud.visible
		hud.visible = false


func _show_hud() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.visible = _hud_was_visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_resume_pressed()


func _on_resume_pressed() -> void:
	StateManager.pop_state()


func _on_settings_pressed() -> void:
	StateManager.push_state("settings")


func _on_quit_to_menu_pressed() -> void:
	StateManager.change_state("main_menu")
