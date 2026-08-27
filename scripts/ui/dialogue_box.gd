class_name DialogueBox
extends CanvasLayer
## Reusable dialogue / monologue text box.
##
## Usage:
##   var db := preload("res://scenes/ui/DialogueBox.tscn").instantiate()
##   get_tree().current_scene.add_child(db)
##   db.show_lines([
##       {"speaker": "Guard", "text": "Stop right there!"},
##       {"text": "You hear footsteps in the distance..."},
##   ])
##   db.finished.connect(_on_dialogue_done)
##
## The player advances by clicking / pressing Space or Enter. You can also
## call advance() from code. Emits `finished` when all lines are shown.

signal finished

const CHAR_SPEED: float = 30.0  ## characters per second for the typewriter

var _lines: Array[Dictionary] = []
var _index: int = 0
var _typing: bool = false
var _tween: Tween

@onready var _panel: PanelContainer = %Panel
@onready var _speaker_label: Label = %SpeakerLabel
@onready var _message_label: Label = %MessageLabel
@onready var _continue_icon: Label = %ContinueIcon


func _ready() -> void:
	hide()
	_panel.hide()


## Show a single monologue line (no speaker name).
func show_monologue(text: String) -> void:
	show_lines([{"text": text}])


## Show a single dialogue line with a speaker name.
func show_dialogue(speaker: String, text: String) -> void:
	show_lines([{"speaker": speaker, "text": text}])


## Show a sequence of lines. Each entry is a Dictionary:
##   { "text": String }                 → monologue line
##   { "speaker": String, "text": String } → dialogue line
func show_lines(lines: Array[Dictionary]) -> void:
	_lines = lines
	_index = 0
	_continue_icon.hide()
	show()
	_show_current_line()


## Advance: skip the typewriter, or move to the next line (or finish).
func advance() -> void:
	if not visible:
		return
	if _typing:
		_skip_typewriter()
	elif _index < _lines.size() - 1:
		_index += 1
		_show_current_line()
	else:
		_close()


## Public accessors for external UI / logic.
func get_speaker() -> String:
	return _speaker_label.text


func get_message() -> String:
	return _message_label.text


func is_open() -> bool:
	return visible


func _show_current_line() -> void:
	var line: Dictionary = _lines[_index]
	var speaker: String = line.get("speaker", "")
	var text: String = line.get("text", "")

	if speaker.is_empty():
		_speaker_label.hide()
	else:
		_speaker_label.show()
		_speaker_label.text = speaker

	_message_label.text = text
	_message_label.visible_characters = 0
	_continue_icon.hide()
	_panel.show()
	_start_typewriter(text.length())


func _start_typewriter(total_chars: int) -> void:
	_typing = true
	_continue_icon.hide()
	# Kill any running tween to avoid overlap.
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_message_label, "visible_characters", total_chars, total_chars / CHAR_SPEED) \
		.set_trans(Tween.TRANS_LINEAR)
	_tween.tween_callback(_on_typewriter_done)


func _skip_typewriter() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_message_label.visible_characters = -1
	_on_typewriter_done()


func _on_typewriter_done() -> void:
	_typing = false
	_continue_icon.show()


func _close() -> void:
	hide()
	_panel.hide()
	_lines = []
	finished.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		get_viewport().set_input_as_handled()
