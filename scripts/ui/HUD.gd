extends CanvasLayer
class_name HUD

@onready var hp_bar: TextureProgressBar = %HPBar
@onready var energy_bar: TextureProgressBar = %EnergyBar
@onready var _task_panel: PanelContainer = %TaskPanel
@onready var _task_title: Label = %TaskTitle
@onready var _task_objectives: VBoxContainer = %TaskObjectives


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
		label.add_theme_font_size_override(&"font_size", 12)
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
