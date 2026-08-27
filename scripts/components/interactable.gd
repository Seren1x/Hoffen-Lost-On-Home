class_name Interactable
extends Area2D

## Signal-based interaction component (observer pattern).
##
## Detects the player (or any node in [member target_group]) that is standing in
## range. When the player presses the "interact" action (E by default) the
## component emits [signal interacted], passing the interactor.
##
## Each prop has its own script that connects to this signal and reacts — that
## script decides what "being interacted with" means (heal, give ammo, etc.).
## The prop script then consumes the prop (e.g. [method Node.queue_free]).

signal interacted(interactor: Node2D)

## The group an interactor must belong to before it can trigger this component.
## Defaults to the "player" group. Change it if your player uses another group.
@export var target_group: String = "player"
## Optional label shown near the prop (reserved for a future prompt UI).
@export var prompt: String = ""
## If true, the component stops responding after the first successful interaction.
@export var consume_on_interact: bool = true

var _nearby: Array[Node2D] = []
var _consumed: bool = false


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_ensure_interact_action()


## Makes sure an "interact" input action exists (mapped to E) even if the project
## has not defined one yet, so the component works out of the box.
func _ensure_interact_action() -> void:
	if InputMap.has_action("interact"):
		return
	InputMap.add_action("interact")
	var ev: InputEventKey = InputEventKey.new()
	ev.physical_keycode = KEY_E
	InputMap.action_add_event("interact", ev)


func _unhandled_input(event: InputEvent) -> void:
	if _consumed:
		return
	if event.is_action_pressed("interact") and not _nearby.is_empty():
		_interact()


func _interact() -> void:
	var interactor: Node2D = _nearby[0]
	if consume_on_interact:
		_consumed = true
	interacted.emit(interactor)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(target_group) and not _nearby.has(body):
		_nearby.append(body)


func _on_body_exited(body: Node2D) -> void:
	_nearby.erase(body)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group(target_group) and not _nearby.has(area):
		_nearby.append(area)


func _on_area_exited(area: Area2D) -> void:
	_nearby.erase(area)


## Returns the interactor currently in range, or null if nobody is close.
func get_interactor() -> Node2D:
	return _nearby.front() if not _nearby.is_empty() else null
