extends CanvasLayer
class_name HUD

const HEART_FULL := preload("res://assets/ui/UI - PostApocalypse/HP/Heart_Full.png")
const HEART_HALF := preload("res://assets/ui/UI - PostApocalypse/HP/Heart_Half.png")
const HEART_EMPTY := preload("res://assets/ui/UI - PostApocalypse/HP/Heart_Empty.png")
const BULLET_FULL := preload("res://assets/ui/UI - PostApocalypse/Bullet Indicators/Pistol-Bullet.png")
const BULLET_EMPTY := preload("res://assets/ui/UI - PostApocalypse/Bullet Indicators/Pistol-Bullet_Empty.png")

@onready var hearts_container: HBoxContainer = %Hearts
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var bullets_container: HBoxContainer = %Bullets

func update_health(current: int, maximum: int) -> void:
	var heart_count: int = hearts_container.get_child_count()
	var hp_per_heart: int = maxi(1, int(float(maximum) / float(heart_count)))

	for i: int in heart_count:
		var heart: TextureRect = hearts_container.get_child(i) as TextureRect
		if not heart:
			continue
		var threshold: int = (i + 1) * hp_per_heart
		var prev_threshold: int = i * hp_per_heart

		if current >= threshold:
			heart.texture = HEART_FULL
		elif current > prev_threshold:
			heart.texture = HEART_HALF
		else:
			heart.texture = HEART_EMPTY

func update_stamina(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current

func update_ammo(current: int, _maximum: int) -> void:
	for i: int in bullets_container.get_child_count():
		var bullet: TextureRect = bullets_container.get_child(i) as TextureRect
		if not bullet:
			continue
		bullet.texture = BULLET_FULL if i < current else BULLET_EMPTY
