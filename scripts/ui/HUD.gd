extends CanvasLayer
class_name HUD

@onready var hp_bar: TextureProgressBar = %HPBar
@onready var energy_bar: TextureProgressBar = %EnergyBar
@onready var _task_panel: PanelContainer = %TaskPanel
@onready var _task_title: Label = %TaskTitle
@onready var _task_objectives: VBoxContainer = %TaskObjectives

## Weapon icons over each slot, in loadout order (1..4).
@onready var _slot_icons: Array[TextureRect] = [
	%Slot1.get_node("WeaponIcon"),
	%Slot2.get_node("WeaponIcon"),
	%Slot3.get_node("WeaponIcon"),
	%Slot4.get_node("WeaponIcon"),
]
## The slot frames themselves, for highlighting the active weapon.
@onready var _slots: Array[TextureRect] = [%Slot1, %Slot2, %Slot3, %Slot4]
## Cooldown bar + label showing the weapon's action delay / reload progress.
@onready var _cooldown_label: Label = %CooldownLabel
@onready var _cooldown_bar: ProgressBar = %CooldownBar
@onready var _cooldown_panel: PanelContainer = %Cooldown

var _weapon: Weapon = null


func _ready() -> void:
	# Group so gameplay scripts (e.g. the player) can find the HUD to update bars.
	add_to_group("hud")
	# Defer so the Player/Weapon _ready (which registers the "weapon" group) has
	# already run by the time we look it up.
	call_deferred("_find_weapon_and_connect")
	_cooldown_panel.visible = false


func _process(_delta: float) -> void:
	if _weapon == null:
		return
	var state: Dictionary = _weapon.get_cooldown_state()
	if not state.get("active", false):
		_cooldown_panel.visible = false
		return
	print("[HUD] cooldown active: ", state)
	_cooldown_panel.visible = true
	var progress: float = float(state.get("progress", 0.0))
	_cooldown_bar.value = progress * 100.0
	if state.get("kind") == "reload":
		_cooldown_label.text = "Reloading..."
		_cooldown_label.add_theme_color_override(&"font_color", Color(0.4, 0.85, 1, 1))
	else:
		_cooldown_label.text = "Pump / Bolt..."
		_cooldown_label.add_theme_color_override(&"font_color", Color(1, 0.85, 0.3, 1))


## Locates the player's Weapon (first node in the "weapon" group) and listens to
## its signals so the slots + info panel stay in sync with the equipped weapon.
func _find_weapon_and_connect() -> void:
	_weapon = get_tree().get_first_node_in_group("weapon") as Weapon
	if _weapon == null:
		print("[HUD] weapon NOT found in group")
		return
	print("[HUD] weapon found: ", _weapon.name)
	_weapon.weapon_changed.connect(_on_weapon_changed)
	_weapon.ammo_changed.connect(_on_ammo_changed)
	# Initial population (the weapon emits weapon_changed on _ready, but the HUD
	# may attach after that, so refresh manually).
	_on_weapon_changed(_weapon.current_index)


func _on_weapon_changed(index: int) -> void:
	if _weapon == null:
		return
	var def: WeaponDefinition = _weapon.get_current_definition()
	if def == null:
		return

	# Highlight the active slot and put each weapon's texture over its slot.
	for i: int in _slot_icons.size():
		var active: bool = i == index
		_slots[i].modulate = Color(1.0, 1.0, 1.0) if active else Color(0.55, 0.55, 0.6)
		if i >= _weapon.get_weapon_count():
			_slot_icons[i].texture = null
			continue
		var def_i: WeaponDefinition = _weapon.weapon_defs[i]
		var tex: Texture2D = def_i.sprite_texture if def_i else null
		_slot_icons[i].texture = tex
		_slot_icons[i].modulate = Color(1, 1, 1, 1) if active else Color(0.6, 0.6, 0.6, 1)
		_slot_icons[i].visible = tex != null


func _on_ammo_changed(_current: int, _maximum: int) -> void:
	pass


func update_health(current: int, maximum: int) -> void:
	hp_bar.max_value = float(maximum)
	hp_bar.value = float(current)


func update_energy(current: float, maximum: float) -> void:
	energy_bar.max_value = maximum
	energy_bar.value = current


## Show a task in the top-right panel. Call once when a task activates.
func show_task(title: String, objectives: Array[TaskObjective]) -> void:
	_task_title.text = title
	_clear_objective_labels()
	for i: int in objectives.size():
		var obj: TaskObjective = objectives[i]
		var label := Label.new()
		label.name = "Obj%d" % i
		label.add_theme_font_size_override(&"font_size", 32)
		label.add_theme_color_override(&"font_color", Color(0.85, 0.85, 0.85, 1))
		label.text = "  %s  %d/%d" % [obj.description, obj.current, obj.required]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_task_objectives.add_child(label)
	_task_panel.show()


## Update a single objective's progress text.
func update_objective(index: int, current: int, required: int) -> void:
	if index >= _task_objectives.get_child_count():
		return
	var label: Label = _task_objectives.get_child(index) as Label
	if not label:
		return
	var obj_desc: String = label.text.substr(0, label.text.rfind("  "))
	label.text = "%s  %d/%d" % [obj_desc, current, required]
	if current >= required:
		label.add_theme_color_override(&"font_color", Color(0.3, 0.9, 0.3, 1))


## Hide the task panel (call when task completes).
func hide_task() -> void:
	_task_panel.hide()
	_clear_objective_labels()


func _clear_objective_labels() -> void:
	for child: Node in _task_objectives.get_children():
		child.queue_free()
