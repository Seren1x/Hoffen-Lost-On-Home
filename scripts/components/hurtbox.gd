class_name Hurtbox
extends Area2D

signal received_damage(damage: int)

@export var health: Health

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		var hitbox := area as Hitbox
		health.take_damage(hitbox.damage)
		received_damage.emit(hitbox.damage)
		#print("hit!")
