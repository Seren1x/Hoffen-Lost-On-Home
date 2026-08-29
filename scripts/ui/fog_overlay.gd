class_name FogOverlay
extends CanvasLayer
## Reusable fog / limited-visibility / vignette overlay.
##
## Add this scene as a child of any level. It works with any camera because it's
## a screen-space CanvasLayer (a full-screen ColorRect with a canvas shader).
##
## Adjust it at runtime from code, e.g.:
##   $FogOverlay.set_fog(0.45, 0.4, 0.85)          # radius, softness, darkness
##   $FogOverlay.set_fog_color(Color(1, 1, 1, 1))  # white mist instead of vignette
##   $FogOverlay.set_enabled(false)
##
## All values can also be set in the inspector. There is no player-facing
## setting — this is purely a developer/designer tool.

## Radius of the clear area, as a fraction of half the screen diagonal (0..1).
@export_range(0.0, 1.0) var radius: float = 0.55:
	set(value):
		radius = value
		_apply("radius", value)

## Softness of the clear → fogged falloff (0..1).
@export_range(0.0, 1.0) var softness: float = 0.35:
	set(value):
		softness = value
		_apply("softness", value)

## Max fog strength at the screen edge (0 = off, 1 = fully opaque).
@export_range(0.0, 1.0) var darkness: float = 0.9:
	set(value):
		darkness = value
		_apply("darkness", value)

## Tint of the fog. Black = vignette; white/gray = mist.
@export var fog_color: Color = Color(0.0, 0.0, 0.0, 1.0):
	set(value):
		fog_color = value
		_apply("fog_color", value)

## Master toggle. When false the overlay is hidden entirely.
@export var enabled: bool = true:
	set(value):
		enabled = value
		if _fog_rect:
			_fog_rect.visible = value

@onready var _fog_rect: ColorRect = %FogRect
@onready var _material: ShaderMaterial = _fog_rect.material as ShaderMaterial


func _ready() -> void:
	_fog_rect.visible = enabled
	# Re-apply any values that were set on the inspector before _ready.
	_apply("radius", radius)
	_apply("softness", softness)
	_apply("darkness", darkness)
	_apply("fog_color", fog_color)


func _apply(param: String, value) -> void:
	if _material:
		_material.set_shader_parameter(param, value)


# ── Public runtime API (developer-adjustable) ──

## Set the core fog look in one call.
func set_fog(p_radius: float, p_softness: float, p_darkness: float, p_color: Color = Color.BLACK) -> void:
	radius = p_radius
	softness = p_softness
	darkness = p_darkness
	fog_color = p_color


func set_radius(p_value: float) -> void:
	radius = p_value


func set_softness(p_value: float) -> void:
	softness = p_value


func set_darkness(p_value: float) -> void:
	darkness = p_value


func set_fog_color(p_value: Color) -> void:
	fog_color = p_value


func set_enabled(p_value: bool) -> void:
	enabled = p_value


func is_enabled() -> bool:
	return enabled
