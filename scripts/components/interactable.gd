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
##
## Detection uses two complementary paths:
##  1. The engine's body_entered/body_exited callbacks (normal gameplay).
##  2. A lightweight direct space query poll every 5 physics frames as a
##     fallback, so detection also works in contexts where the monitoring
##     callbacks are never delivered (e.g. embedded playtest runs).

signal interacted(interactor: Node2D)

## The group an interactor must belong to before it can trigger this component.
## Defaults to the "player" group. Change it if your player uses another group.
@export var target_group: String = "player"
## Optional label shown near the prop (reserved for a future prompt UI).
@export var prompt: String = ""
## If true, the component stops responding after the first successful interaction.
@export var consume_on_interact: bool = true

## How often (in physics frames) the fallback space-query poll runs.
const POLL_INTERVAL_FRAMES: int = 5

var _nearby: Array[Node2D] = []
var _consumed: bool = false


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


## Fallback overlap poll: queries the physics space directly with this area's
## collision shapes and keeps [member _nearby] in sync with the result. This
## covers contexts where body_entered/body_exited are never delivered.
func _physics_process(_delta: float) -> void:
	if _consumed or not monitoring:
		return
	if Engine.get_physics_frames() % POLL_INTERVAL_FRAMES != 0:
		return
	var found: Array[Node2D] = _query_overlap()
	var kept: Array[Node2D] = []
	for node: Node2D in _nearby:
		if found.has(node):
			kept.append(node)
	for node: Node2D in found:
		if not _nearby.has(node):
			kept.append(node)
	_nearby = kept


## Returns every node in [member target_group] whose shapes overlap this area's
## own collision shapes, using a direct space query.
func _query_overlap() -> Array[Node2D]:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space == null:
		return []
	var result: Array[Node2D] = []
	for child: Node in get_children():
		var shape_node: CollisionShape2D = child as CollisionShape2D
		if shape_node == null or shape_node.shape == null or shape_node.disabled:
			continue
		var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		query.shape = shape_node.shape
		query.transform = global_transform * shape_node.transform
		query.collision_mask = collision_mask
		query.collide_with_bodies = true
		query.collide_with_areas = false
		for hit: Dictionary in space.intersect_shape(query, 4):
			var collider: Node = hit.get("collider")
			if collider is Node2D and (collider as Node2D).is_in_group(target_group) and not result.has(collider):
				result.append(collider)
	return result


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
