extends SceneTree
func _init() -> void:
	var paths := [
		"res://assets/sprites/Character - PostApocalypse/Guns/Bullets/Pistol-bullet_Bullet.png",
		"res://assets/sprites/Character - PostApocalypse/Guns/Bullets/Shotgun-bullet.png",
		"res://assets/sprites/Character - PostApocalypse/Guns/Bullets/Pistol-bullet_Casting.png",
		"res://assets/sprites/Character - PostApocalypse/Guns/Bullets/Gun-bullet_Casing.png",
	]
	for p in paths:
		var t = load(p) as Texture2D
		if t:
			print(p.split("/")[-1], " = ", t.get_width(), "x", t.get_height())
		else:
			print("MISSING: ", p)
	quit(0)
