class_name WeaponDefinition
extends Resource

## Reusable weapon definition. A single Weapon node can hold a list of these
## and switch between them. Each definition describes how a weapon looks, how
## fast it fires, how much damage it deals, its ammo capacity, its spread
## (for shotguns), and its audio.

@export var weapon_name: String = "Pistol"
@export var display_name: String = "Pistol"

## Ammo in the magazine.
@export var max_ammo: int = 12

## Damage dealt per bullet (per pellet for shotguns).
@export var damage: int = 10

## Seconds between shots (AttackCooldown wait_time).
@export var fire_rate: float = 0.25

## Seconds to reload (ReloadCooldown wait_time).
@export var reload_time: float = 1.5

## Number of bullets fired per shot. >1 simulates shotgun pellets.
@export var bullet_count: int = 1

## Total spread (degrees) across all pellets. Only used when bullet_count > 1.
@export var spread_degrees: float = 0.0

## Bullet travel speed.
@export var bullet_speed: float = 800.0

## Max distance a bullet travels before despawning (<=0 = unlimited).
@export var bullet_max_range: float = 200.0

## Scene to spawn as the projectile.
@export var bullet_scene: PackedScene

## Weapon viewport sprite and its scale.
@export var sprite_texture: Texture2D
@export var sprite_scale: Vector2 = Vector2(1, 1)

## Where the gun sprite sits in the player's hand, relative to the Weapon node
## (which is at the player's center). Y-offset re-centers guns of different
## heights. Per-weapon, so each gun can look correctly held.
@export var sprite_offset: Vector2 = Vector2.ZERO

## Where bullets spawn, relative to the gun sprite's pivot (the barrel tip).
## Per-weapon, because each gun's barrel is at a different spot on its sprite.
@export var muzzle_offset: Vector2 = Vector2(15, 0)

## Audio.
@export var shoot_sfx: AudioStream
## Sound that plays after each shot while the action cycles (pump rack, bolt,
## slide). Gives weapons like the shotgun a delay between rounds.
@export var action_sfx: AudioStream
@export var reload_sfx: AudioStream
@export var empty_sfx: AudioStream

## Seconds the action takes to cycle after a shot before the next shot can fire
## (e.g. the shotgun pump time). 0 = no extra delay.
@export var action_delay: float = 0.0
