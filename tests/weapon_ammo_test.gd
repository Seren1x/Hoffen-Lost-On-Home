extends Node

## Headless tests for the limited-ammo weapon system (per-weapon mag + reserve).
## Run with the Ziva test runner (res://tests).
##
## NOTE ON THE RUNNER: it executes tests before any scene tree is live, so
## Weapon instances can never enter the tree (no _ready, onready vars stay
## Nil). _make_weapon() therefore wires the node up manually. The bullet-
## spawning half of player_shoot() needs a live tree too, so shot costs are
## simulated with _spend(); the real fire path is verified in-game instead.

const WEAPON_SCENE: PackedScene = preload("res://scenes/props/Weapon.tscn")
const PISTOL: WeaponDefinition = preload("res://assets/objects/WeaponBaru/Pistol.tres")
const ASSAULT_RIFLE: WeaponDefinition = preload("res://assets/objects/WeaponBaru/AssaultRifle.tres")
const SHOTGUN: WeaponDefinition = preload("res://assets/objects/WeaponBaru/Shotgun.tres")
const SNIPER: WeaponDefinition = preload("res://assets/objects/WeaponBaru/SniperRifle.tres")

var _fails: int = 0


## The runner's test node is not inside the scene tree (its children never fire
## _ready), so get the real SceneTree from the engine's main loop instead and
## attach instances to its root ourselves.
func _scene_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		_fails += 1
		push_error("FAIL: " + message)
		print("FAIL: " + message)


func _make_weapon() -> Weapon:
	var weapon: Weapon = WEAPON_SCENE.instantiate()
	# The runner never puts nodes in the tree, so @onready vars are Nil and
	# _ready never runs. Wire what the ammo logic touches, manually:
	weapon.weapon_sprite = weapon.get_node("Texture")
	weapon.bullet_spawn_pos = weapon.get_node("Texture/BulletSpawnPoint")
	weapon.attack_cooldown = weapon.get_node("AttackCooldown")
	weapon.reload_cooldown = weapon.get_node("ReloadCooldown")
	weapon.action_cooldown = weapon.get_node("ActionCooldown")
	weapon.sfx = weapon.get_node("Sfx")
	weapon.action_sfx_player = weapon.get_node("ActionSfx")
	weapon.top_guide_line = weapon.get_node("TopGuideLine")
	weapon.bottom_guide_line = weapon.get_node("BottomGuideLine")
	weapon.laser = weapon.get_node("Texture/Laser")
	# The starting loadout is EMPTY (unarmed); equip on demand.
	weapon._current_def = null
	weapon._init_ammo_states()
	return weapon


## Arms the weapon with the given definition (as a WeaponProp pickup would).
func _arm(w: Weapon, def: WeaponDefinition) -> void:
	w.add_weapon(def)


## Simulates [param rounds] spent shots. (The bullet-spawning half of
## player_shoot() can't run without a live scene tree in the runner.)
func _spend(w: Weapon, rounds: int) -> void:
	w._set_mag(w.get_mag() - rounds)


## The player starts UNARMED; picking up the pistol grants 6/12.
func test_starting_loadout_is_unarmed_then_pistol_6_12() -> void:
	var w: Weapon = _make_weapon()
	_check(w.get_weapon_count() == 0, "starting loadout is empty (unarmed)")
	_check(w.get_current_definition() == null, "no weapon equipped at start")
	_check(w.get_mag() == 0 and w.get_reserve() == 0, "unarmed: no ammo pools")
	# Unarmed guards: shoot / reload / feed must all be safe no-ops.
	w.player_shoot()
	w.weapon_reload()
	w.add_magazines(1)
	_check(w.get_mag() == 0 and w.get_reserve() == 0, "unarmed actions change nothing")
	# Picking up the pistol prop arms the player with the limited bundle.
	w.add_weapon(PISTOL)
	_check(w.get_weapon_count() == 1, "pistol pickup arms the player")
	_check(w.get_current_definition() == PISTOL, "pistol is equipped after pickup")
	_check(w.get_mag() == 6, "pistol pickup grants mag 6 (got %d)" % w.get_mag())
	_check(w.get_reserve() == 12, "pistol pickup grants reserve 12 (got %d)" % w.get_reserve())
	_check(PISTOL.pickup_reserve_ammo == 12, "pistol def pickup_reserve_ammo is 12")
	_check(ASSAULT_RIFLE.pickup_reserve_ammo == 60, "AR def pickup_reserve_ammo is 60")
	_check(SHOTGUN.pickup_reserve_ammo == 10, "shotgun def pickup_reserve_ammo is 10")
	_check(SNIPER.pickup_reserve_ammo == 10, "sniper def pickup_reserve_ammo is 10")
	w.free()


## Firing decrements the mag only (reserve untouched); dry-fire with an empty
## mag does nothing and never crashes.
func test_shoot_decrements_mag_only() -> void:
	var w: Weapon = _make_weapon()
	_arm(w, PISTOL)
	_spend(w, 1)
	_check(w.get_mag() == 5, "after one shot mag is 5 (got %d)" % w.get_mag())
	_check(w.get_reserve() == 12, "reserve untouched by shooting (got %d)" % w.get_reserve())
	# Simulate running dry, then try firing again (early return path in
	# player_shoot: no crash, mag stays 0).
	_spend(w, 5)
	w.player_shoot()
	_check(w.get_mag() == 0, "dry-fire: mag stays 0 (got %d)" % w.get_mag())
	w.free()


## Reload transfers rounds from reserve to mag: 6/12 -> fire all -> reload -> 6/6.
func test_reload_consumes_reserve() -> void:
	var w: Weapon = _make_weapon()
	_arm(w, PISTOL)
	_spend(w, 6)
	_check(w.get_mag() == 0 and w.get_reserve() == 12, "empty mag keeps reserve 12")
	w.weapon_reload()
	_check(w.get_mag() == 6, "reload refills mag to 6 (got %d)" % w.get_mag())
	_check(w.get_reserve() == 6, "reload consumes reserve down to 6 (got %d)" % w.get_reserve())
	w.free()


## Partial reload tops up the mag from what the reserve has left: 2/3 -> reload -> 5/0.
func test_partial_reload_takes_only_what_reserve_has() -> void:
	var w: Weapon = _make_weapon()
	_arm(w, PISTOL)
	_spend(w, 4)          # 2/12
	w.add_ammo(-12)       # drain the starting reserve: 2/0
	w.add_ammo(3)         # give exactly 3 spare rounds: 2/3
	w.weapon_reload()     # needs 4, reserve has 3 -> takes all
	_check(w.get_mag() == 5, "partial reload fills mag to 5 (got %d)" % w.get_mag())
	_check(w.get_reserve() == 0, "partial reload drains reserve to 0 (got %d)" % w.get_reserve())
	w.free()


## Reload with a full mag does nothing (needed <= 0 early return).
func test_reload_blocked_when_mag_full() -> void:
	var w: Weapon = _make_weapon()
	_arm(w, PISTOL)
	w.weapon_reload()
	_check(w.get_mag() == 6, "full mag: reload does nothing (got %d)" % w.get_mag())
	_check(w.get_reserve() == 12, "full mag: reserve untouched (got %d)" % w.get_reserve())
	w.free()


## No reserve -> dry click: reload transfers nothing.
func test_reload_blocked_when_reserve_empty() -> void:
	var w: Weapon = _make_weapon()
	_arm(w, PISTOL)
	_spend(w, 6)
	w.weapon_reload()  # 6/6 now
	w.add_ammo(-6)     # drain the remaining spare rounds: 6/0
	_spend(w, 6)
	w.weapon_reload()  # reserve empty: dry click
	_check(w.get_mag() == 0, "no reserve: mag stays 0 (got %d)" % w.get_mag())
	_check(w.get_reserve() == 0, "no reserve stays 0")
	w.free()


## Ammo prop API: 1 prop = 1 magazine of the equipped weapon.
func test_add_magazines_gives_one_mag() -> void:
	var w: Weapon = _make_weapon()
	_arm(w, PISTOL)
	w.add_magazines(1)
	_check(w.get_reserve() == 18, "1 prop = +6 pistol rounds (got %d)" % w.get_reserve())
	w.free()

	var w2: Weapon = _make_weapon()
	w2.add_weapon(ASSAULT_RIFLE)
	w2.add_magazines(1)
	_check(w2.get_reserve() == 90, "1 prop = +30 AR rounds (got %d)" % w2.get_reserve())
	w2.free()


## Picking up a new weapon adds it with its limited bundle and equips it.
func test_add_weapon_grants_limited_ammo() -> void:
	var w: Weapon = _make_weapon()
	var added: bool = w.add_weapon(ASSAULT_RIFLE)
	_check(added, "AR pickup reports newly added")
	_check(w.get_weapon_count() == 1, "loadout grew to 1")
	_check(w.get_current_definition() == ASSAULT_RIFLE, "AR is equipped after pickup")
	_check(w.get_mag() == 30, "AR pickup grants mag 30 (got %d)" % w.get_mag())
	_check(w.get_reserve() == 60, "AR pickup grants reserve 60 (got %d)" % w.get_reserve())
	w.free()


## Picking up a weapon you already own converts into spare ammo instead.
func test_duplicate_pickup_converts_to_ammo() -> void:
	var w: Weapon = _make_weapon()
	_check(w.add_weapon(ASSAULT_RIFLE), "first AR pickup adds weapon")
	_check(not w.add_weapon(ASSAULT_RIFLE), "duplicate AR pickup reports already owned")
	_check(w.get_weapon_count() == 1, "loadout does not duplicate")
	# Prop logic converts the duplicate into its bundled reserve rounds, which
	# join THAT weapon's pool (not the equipped weapon's).
	_check(w.add_reserve_to(ASSAULT_RIFLE, ASSAULT_RIFLE.pickup_reserve_ammo), "add_reserve_to works on owned weapon")
	_check(w.get_reserve_of(ASSAULT_RIFLE) == 120, "duplicate converts to +60 AR reserve (got %d)" % w.get_reserve_of(ASSAULT_RIFLE))
	_check(not w.add_reserve_to(SHOTGUN, 5), "add_reserve_to fails on unowned weapon")
	w.free()


## Each weapon keeps its own pools; switching does not refill.
func test_switch_preserves_per_weapon_ammo() -> void:
	var w: Weapon = _make_weapon()
	_arm(w, PISTOL)
	w.add_weapon(ASSAULT_RIFLE)
	_spend(w, 3)
	_check(w.get_mag() == 27, "AR mag after 3 shots (got %d)" % w.get_mag())
	w.switch_weapon(0)
	_check(w.get_mag() == 6 and w.get_reserve() == 12, "pistol pools intact (got %d/%d)" % [w.get_mag(), w.get_reserve()])
	w.switch_weapon(1)
	_check(w.get_mag() == 27, "AR mag preserved across switches (got %d)" % w.get_mag())
	w.free()
