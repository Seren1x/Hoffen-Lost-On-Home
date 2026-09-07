extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal on_transition_finished

func _ready() -> void:
	color_rect.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)


func _on_animation_finished(anim_name):
	if anim_name == "fade_to_black":
		on_transition_finished.emit()
		animation_player.play("fade_to_normal")
	elif anim_name == "fade_to_normal":
		color_rect.visible = false

func transition():
	# Guard: if this is called before _ready() has run (e.g. an autoload
	# triggered the fade before the FadeTransition autoload finished starting
	# up), defer until the node is ready instead of crashing on a Nil ColorRect.
	if color_rect == null:
		call_deferred("transition")
		return
	color_rect.visible = true
	animation_player.play("fade_to_black")
