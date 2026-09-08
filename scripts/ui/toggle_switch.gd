@tool
extends Control
class_name ToggleSwitch

## A texture-driven on/off toggle. Uses 4 textures directly (no theme lookup):
## on/off x normal/hover. Emits `toggled(bool)` on click. Drop-in replacement
## for a CheckButton when you want real texture swapping.

signal toggled(on: bool)

@export var texture_on: Texture2D:
	set(v):
		texture_on = v
		_update_texture()
@export var texture_on_hover: Texture2D:
	set(v):
		texture_on_hover = v
		_update_texture()
@export var texture_off: Texture2D:
	set(v):
		texture_off = v
		_update_texture()
@export var texture_off_hover: Texture2D:
	set(v):
		texture_off_hover = v
		_update_texture()

## Current state (false = OFF, true = ON). Setting it updates the texture but
## does NOT emit `toggled` (so you can sync it from settings without a loop).
@export var value: bool = false:
	set(v):
		value = v
		_update_texture()

var _hovered: bool = false
var _texture_rect: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _texture_rect == null:
		_texture_rect = TextureRect.new()
		_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_texture_rect)
	_update_texture()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		value = not value
		toggled.emit(value)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovered = true
		_update_texture()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovered = false
		_update_texture()

func _update_texture() -> void:
	if _texture_rect == null:
		return
	var t: Texture2D = null
	if value:
		t = texture_on_hover if (_hovered and texture_on_hover) else texture_on
	else:
		t = texture_off_hover if (_hovered and texture_off_hover) else texture_off
	if t != null:
		_texture_rect.texture = t
