extends CharacterBody2D

func _on_health_died(overkill: int) -> void:
	queue_free()
