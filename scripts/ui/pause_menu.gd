extends CanvasLayer
class_name PauseMenu

## Health/energy are shown as bars (same art as the HUD); weapon/objective as
## panels. All separately draggable in the editor.
@onready var _health_bar: TextureProgressBar = %HealthBar
@onready var _energy_bar: TextureProgressBar = %EnergyBar
@onready var _weapon_panel: PanelContainer = %WeaponPanel
@onready var _objective_panel: PanelContainer = %ObjectivePanel
@onready var _weapon_list: HBoxContainer = %WeaponList
@onready var _weapon_label: Label = %WeaponLabel
@onready var _weapon_info: GridContainer = %WeaponInfo
@onready var _objective_title: Label = %ObjectiveTitle
@onready var _objective_label: Label = %ObjectiveLabel

## Whether the HUD was visible before we hid it, so we can restore it on resume.
var _hud_was_visible: bool = false

## Weapon loadout snapshot for the pause menu (one dictionary per owned weapon).
var _weapons: Array = []
var _weapon_buttons: Array[TextureButton] = []
var _selected_weapon: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%ResumeButton.pressed.connect(_on_resume_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%ExitToMainButton.pressed.connect(_on_quit_to_menu_pressed)


func state_enter(data: Dictionary = {}) -> void:
	# Hide the gameplay HUD while paused — its info is shown here instead.
	_hide_hud()

	# Health (bar)
	_health_bar.visible = data.has("hp")
	if data.has("hp"):
		_health_bar.max_value = float(data.max_hp)
		_health_bar.value = float(data.hp)

	# Energy / stamina (bar)
	_energy_bar.visible = data.has("energy")
	if data.has("energy"):
		_energy_bar.max_value = float(data.max_energy)
		_energy_bar.value = float(data.energy)

	# Weapon list + details
	_build_weapon_list(data)

	# Objective
	_show_objective(data)


func state_exit() -> void:
	_show_hud()


## Rebuilds the weapon list (one button per owned weapon) and shows the details
## of the equipped weapon by default. Clicking a button shows that weapon's
## info, read from its WeaponDefinition (.tres).
func _build_weapon_list(data: Dictionary) -> void:
	for child in _weapon_list.get_children():
		child.queue_free()
	_weapon_buttons.clear()
	_weapons = data.get("weapons", [])
	_weapon_panel.visible = not _weapons.is_empty()
	_selected_weapon = -1
	if _weapons.is_empty():
		return
	for i in _weapons.size():
		var w: Dictionary = _weapons[i]
		# Each entry is a box filled (mostly) by the weapon's own sprite,
		# taken from its WeaponDefinition (.tres) sprite_texture.
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(120, 64)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.texture_normal = w.get("texture")
		btn.focus_mode = Control.FOCUS_NONE
		btn.tooltip_text = String(w.get("name", "?"))
		btn.pressed.connect(_select_weapon.bind(i))
		_weapon_list.add_child(btn)
		_weapon_buttons.append(btn)
	_select_weapon(int(data.get("weapon_index", 0)))


func _select_weapon(index: int) -> void:
	if index < 0 or index >= _weapons.size():
		return
	_selected_weapon = index
	# Highlight the selected box, dim the rest.
	for i in _weapon_buttons.size():
		_weapon_buttons[i].modulate = Color(1, 1, 1, 1) if i == index else Color(0.55, 0.55, 0.6, 1)
	var w: Dictionary = _weapons[index]
	_weapon_label.text = String(w.get("name", "?"))
	# Rebuild the stat cells. The info grid's `columns` wraps them into (e.g.)
	# 2 or 3 columns instead of one tall column.
	for child in _weapon_info.get_children():
		child.queue_free()
	for stat: String in _weapon_stats(w):
		var cell := Label.new()
		cell.text = stat
		cell.add_theme_font_size_override("font_size", 20)
		cell.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
		_weapon_info.add_child(cell)


## The stat lines for one weapon, built from its WeaponDefinition (.tres).
## Each becomes a cell in the info grid, so the grid's `columns` controls how
## many columns they wrap into.
func _weapon_stats(w: Dictionary) -> Array[String]:
	var stats: Array[String] = []
	stats.append("Firepower:  %d" % int(w.get("damage", 0)))
	stats.append("Ammo:  %d / %d" % [int(w.get("mag", 0)), int(w.get("max_ammo", 0))])
	stats.append("Reserve:  %d" % int(w.get("reserve", 0)))
	stats.append("Fire rate:  %.2f s" % float(w.get("fire_rate", 0.0)))
	stats.append("Reload:  %.2f s" % float(w.get("reload_time", 0.0)))
	if float(w.get("action_delay", 0.0)) > 0.0:
		stats.append("Delay:  %.2f s" % float(w.get("action_delay", 0.0)))
	if int(w.get("bullet_count", 1)) > 1:
		stats.append("Pellets:  %d" % int(w.get("bullet_count", 1)))
	if float(w.get("spread", 0.0)) > 0.0:
		stats.append("Spread:  %.1f deg" % float(w.get("spread", 0.0)))
	stats.append("Range:  %.0f" % float(w.get("range", 0.0)))
	return stats


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
