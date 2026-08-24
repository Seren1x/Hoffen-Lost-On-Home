extends CanvasLayer
class_name HUD

@onready var hp_bar: TextureProgressBar = %HPBar
@onready var energy_bar: TextureProgressBar = %EnergyBar


func update_health(current: int, maximum: int) -> void:
	hp_bar.max_value = float(maximum)
	hp_bar.value = float(current)


func update_energy(current: float, maximum: float) -> void:
	energy_bar.max_value = maximum
	energy_bar.value = current
