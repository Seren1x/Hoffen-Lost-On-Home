class_name Enemy
extends CharacterBody2D

## Base enemy class that centralises shared behaviour so every enemy uses the
## universal Health component (health.gd) as the single source of HP truth.
##
## - HP lives in the "Health" child (a Health component).
## - Damage comes in through [method take_damage] (used by bullets/melee) and,
##   if a "Hurtbox" child exists, through the Hurtbox component too (so any
##   Hitbox can damage it as well).
## - On being hit it flashes [member flash_sprite] with [member flash_color].
## - On death it emits [signal died] and calls [method _die], which subclasses
##   override for death animations / loot drops.

signal died

@export var max_health: int = 10
## Color the sprite flashes when the enemy is hit.
@export var flash_color: Color = Color.RED
## Seconds for the hit-flash to fade back to normal.
@export var flash_duration: float = 0.2

## The node flashed on hit (usually an AnimatedSprite2D). Set by subclasses.
var flash_sprite: Node2D

var health: Health
var dead: bool = false

var _flash_tween: Tween


func _ready() -> void:
	# Let subclasses configure (flash_sprite, max_health, ...) before we wire HP.
	_ready_enemy()

	health = get_node_or_null("Health") as Health
	if health != null:
		health.max_health = max_health
		health.died.connect(_on_health_died)
		var hurtbox: Hurtbox = get_node_or_null("Hurtbox") as Hurtbox
		if hurtbox != null:
			hurtbox.health = health

	add_to_group("enemies")


## Hook run before health is wired up. Subclasses should set [member flash_sprite]
## here and do their own one-time setup.
func _ready_enemy() -> void:
	pass


## Public damage entry point used by bullets and melee hitboxes.
func take_damage(amount: int) -> void:
	if dead or health == null:
		return
	health.take_damage(amount)
	_flash()


## Flash the sprite a hit color, then fade it back to white.
func _flash() -> void:
	if flash_sprite == null:
		return
	if _flash_tween:
		_flash_tween.kill()
	flash_sprite.modulate = flash_color
	_flash_tween = create_tween()
	_flash_tween.tween_property(flash_sprite, "modulate", Color.WHITE, flash_duration)


func _on_health_died(_overkill: int) -> void:
	dead = true
	died.emit()
	_die()


## Called when HP reaches 0. Default frees the enemy; subclasses override to play
## a death animation / drop loot (they must free the enemy themselves).
func _die() -> void:
	queue_free()
