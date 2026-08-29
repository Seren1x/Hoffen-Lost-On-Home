extends CanvasLayer
class_name PauseMenu

@onready var _stats_panel: VBoxContainer = %StatsPanel
@onready var _hp_label: Label = %HPLabel
@onready var _energy_label: Label = %EnergyLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%ResumeButton.pressed.connect(_on_resume_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%ExitToMainButton.pressed.connect(_on_quit_to_menu_pressed)

func state_enter(data: Dictionary = {}) -> void:
	# PlayingState passes a stats snapshot in `data` when it calls
	# push_state("paused", data) — no reaching into HUD directly.
	if data.has("hp"):
		_hp_label.text = "HP: %d / %d" % [int(data.hp), int(data.max_hp)]
		_energy_label.text = "Energy: %d / %d" % [int(data.energy), int(data.max_energy)]
		_stats_panel.show()
	else:
		_stats_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_resume_pressed()

func _on_resume_pressed() -> void:
	StateManager.pop_state()

func _on_settings_pressed() -> void:
	StateManager.push_state("settings")

func _on_quit_to_menu_pressed() -> void:
	StateManager.change_state("main_menu")
