@tool
extends ColorRect
class_name PanelBackground

## Reusable main-menu background: a black backdrop with several vertical,
## slightly-tilted polygon panels that reveal slices of a background image.
## Each panel has its OWN height and vertical position. All values are
## inspector-adjustable; @tool so changes show live in the editor viewport.

const SHADER := preload("res://shaders/panel_background.gdshader")
const MAX_PANELS := 16

@export var city_texture: Texture2D:
	set(v):
		city_texture = v
		_update()
@export var tint: Color = Color.WHITE:
	set(v):
		tint = v
		_update()
@export var panel_count: int = 4:
	set(v):
		panel_count = clampi(v, 1, MAX_PANELS)
		_resize_arrays()
		_update()
@export var panel_width: float = 0.22:
	set(v):
		panel_width = v
		_update()
@export var panel_gap: float = 0.012:
	set(v):
		panel_gap = v
		_update()
@export var h_offset: float = 0.0:
	set(v):
		h_offset = v
		_update()
@export var tilt: float = 0.04:
	set(v):
		tilt = v
		_update()
@export var v_offset: float = 0.0:
	set(v):
		v_offset = v
		_update()

## Fill for the empty space OUTSIDE the panels (left/right of the fragment).
## If `backdrop_texture` is set, that image is used; otherwise this solid color.
@export var backdrop_color: Color = Color(0.0, 0.0, 0.0, 1.0):
	set(v):
		backdrop_color = v
		_update()

## Optional image for the empty space OUTSIDE the panels. The panels simply
## carve through it, so it is shaped by panel size, gap, tilt and bob.
@export var backdrop_texture: Texture2D:
	set(v):
		backdrop_texture = v
		_update()

## Tint applied to the backdrop image (multiplied). White = original.
@export var backdrop_tint: Color = Color.WHITE:
	set(v):
		backdrop_tint = v
		_update()

## Extend the city image past the outermost panels, following the tilt angle:
## left of the leftmost panel and/or right of the rightmost panel. The gaps
## BETWEEN panels stay backdrop-colored.
@export var edge_fill_left: bool = false:
	set(v):
		edge_fill_left = v
		_update()
@export var edge_fill_right: bool = false:
	set(v):
		edge_fill_right = v
		_update()

## Height of each panel (fraction of screen height). Index = panel number,
## starting at 0 (leftmost). Edit per panel.
@export var panel_heights: Array = [1.0, 1.0, 1.0, 1.0]:
	set(v):
		panel_heights = v
		_update()

## Vertical center of each panel (0=top, 0.5=center, 1=bottom). Index = panel.
@export var panel_v_centers: Array = [0.5, 0.5, 0.5, 0.5]:
	set(v):
		panel_v_centers = v
		_update()

## Bob phase (radians) per panel. 0 = normal; PI = moves opposite. So
## [0, PI, 0, PI] makes panels 2 & 4 bob opposite to 1 & 3.
@export var panel_phases: Array = [0.0, 3.141592653589793, 0.0, 3.141592653589793]:
	set(v):
		panel_phases = v
		_update()

## Animation: gently bob the whole panel band up/down (runtime only).
@export var anim_enabled: bool = true:
	set(v):
		anim_enabled = v
		_update()
@export var anim_speed: float = 1.0:
	set(v):
		anim_speed = v
		_update()
@export var anim_amplitude: float = 0.04:
	set(v):
		anim_amplitude = v
		_update()

var _mat: ShaderMaterial = null
var _anim_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resize_arrays()
	_update()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not anim_enabled:
		return
	_anim_time += delta
	_update_anim()

func _ensure_material() -> void:
	if _mat == null or _mat.shader != SHADER:
		_mat = ShaderMaterial.new()
		_mat.shader = SHADER
	# Only reassign when it actually changes. Re-assigning `material` every
	# frame (e.g. while dragging a slider) makes the editor re-process the node
	# and can knock the Inspector row out from under the mouse.
	if material != _mat:
		material = _mat

func _resize_arrays() -> void:
	# Keep the per-panel arrays in sync with panel_count.
	panel_heights = _pad_array(panel_heights, panel_count, 1.0)
	panel_v_centers = _pad_array(panel_v_centers, panel_count, 0.5)
	panel_phases = _pad_array(panel_phases, panel_count, 0.0)

func _pad_array(arr: Array, count: int, fill: float) -> Array:
	var out: Array = arr.duplicate()
	while out.size() < count:
		out.append(fill)
	if out.size() > count:
		out.resize(count)
	return out

func _update() -> void:
	if not is_inside_tree():
		return
	_ensure_material()
	_mat.set_shader_parameter("city_tex", city_texture)
	_mat.set_shader_parameter("use_texture", city_texture != null)
	_mat.set_shader_parameter("tint", tint)
	_mat.set_shader_parameter("panel_count", panel_count)
	_mat.set_shader_parameter("panel_width", panel_width)
	_mat.set_shader_parameter("panel_gap", panel_gap)
	_mat.set_shader_parameter("h_offset", h_offset)
	_mat.set_shader_parameter("tilt", tilt)
	_mat.set_shader_parameter("v_offset", v_offset)
	_mat.set_shader_parameter("backdrop", backdrop_color)
	_mat.set_shader_parameter("backdrop_tex", backdrop_texture)
	_mat.set_shader_parameter("use_backdrop_tex", backdrop_texture != null)
	_mat.set_shader_parameter("backdrop_tint", backdrop_tint)
	_mat.set_shader_parameter("edge_fill_left", edge_fill_left)
	_mat.set_shader_parameter("edge_fill_right", edge_fill_right)

	# Per-panel arrays (padded to MAX_PANELS for the fixed-size shader array).
	var h := PackedFloat32Array()
	var vc := PackedFloat32Array()
	var ph := PackedFloat32Array()
	for i in MAX_PANELS:
		h.append(panel_heights[i] if i < panel_heights.size() else 1.0)
		vc.append(panel_v_centers[i] if i < panel_v_centers.size() else 0.5)
		ph.append(panel_phases[i] if i < panel_phases.size() else 0.0)
	_mat.set_shader_parameter("panel_heights", h)
	_mat.set_shader_parameter("panel_v_centers", vc)
	_mat.set_shader_parameter("panel_phases", ph)

	# Animation uniforms.
	_mat.set_shader_parameter("anim_enabled", anim_enabled)
	_mat.set_shader_parameter("anim_speed", anim_speed)
	_mat.set_shader_parameter("anim_amplitude", anim_amplitude)
	_mat.set_shader_parameter("anim_time", _anim_time)

func _update_anim() -> void:
	_ensure_material()
	_mat.set_shader_parameter("anim_time", _anim_time)
