class_name WeaponSystem
extends Node

signal ammo_changed(ammo_in_magazine: int, reserve_ammo: int, weapon_id: String)
signal weapon_changed(weapon_id: String, display_name: String)
signal reload_started(weapon_id: String)
signal reload_finished(weapon_id: String)

const BULLET_SCENE = preload("res://scenes/weapons/Bullet.tscn")
const ROCKET_SCENE = preload("res://scenes/weapons/Rocket.tscn")

var owner_body: Node2D
var projectile_parent: Node
var weapons: Dictionary = {}
var unlocked_weapons: Dictionary = {}
var current_weapon_id := "pistol"
var last_fire_time := -100.0
var reloading := false

var reload_timer: Timer

func _ready() -> void:
	reload_timer = Timer.new()
	reload_timer.one_shot = true
	add_child(reload_timer)
	reload_timer.timeout.connect(_finish_reload)
	_create_default_weapons()
	_emit_weapon_state()

func setup(p_owner: Node2D, p_projectile_parent: Node = null) -> void:
	owner_body = p_owner
	projectile_parent = p_projectile_parent

func try_fire(origin: Vector2, direction: Vector2, owner_team: String = Constants.TEAM_PLAYER) -> bool:
	var weapon: WeaponData = get_current_weapon()
	if weapon == null or reloading:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_fire_time < weapon.fire_rate:
		return false
	if weapon.ammo_in_magazine <= 0:
		start_reload()
		return false

	weapon.ammo_in_magazine -= 1
	last_fire_time = now
	for _pellet_index in range(maxi(1, weapon.pellets)):
		var spread_angle: float = deg_to_rad(randf_range(-weapon.spread, weapon.spread))
		var shot_direction: Vector2 = direction.normalized().rotated(spread_angle)
		var projectile: Node2D = _create_projectile(weapon.projectile_type)
		_get_projectile_parent().add_child(projectile)
		projectile.global_position = origin
		if projectile.has_method("setup"):
			projectile.setup(shot_direction, weapon.damage, owner_team, weapon.bullet_speed)
	EffectSpawner.spawn_effect(weapon.muzzle_flash_type, origin, Utility.direction_from_delta(direction.x))
	AudioManager.play_sfx("grenade_throw" if weapon.id == "rpg" else "shoot_" + weapon.id)
	_emit_weapon_state()
	return true

func start_reload() -> void:
	var weapon := get_current_weapon()
	if weapon == null or reloading:
		return
	if weapon.reserve_ammo <= 0 or weapon.ammo_in_magazine >= weapon.magazine_size:
		return
	reloading = true
	reload_started.emit(weapon.id)
	AudioManager.play_sfx("reload")
	reload_timer.start(weapon.reload_time)

func switch_weapon(weapon_id: String) -> void:
	if not weapons.has(weapon_id):
		return
	if not has_weapon(weapon_id):
		return
	if current_weapon_id == weapon_id:
		return
	reloading = false
	reload_timer.stop()
	current_weapon_id = weapon_id
	_emit_weapon_state()

func add_reserve_ammo(amount: int, weapon_id: String = "") -> void:
	var id: String = weapon_id if weapon_id != "" else current_weapon_id
	if not weapons.has(id):
		return
	var weapon: WeaponData = weapons[id]
	weapon.reserve_ammo += amount
	_emit_weapon_state()

func unlock_weapon(weapon_id: String, reserve_bonus: int = 0) -> void:
	if not weapons.has(weapon_id):
		return
	unlocked_weapons[weapon_id] = true
	var weapon: WeaponData = weapons[weapon_id]
	weapon.reserve_ammo += maxi(0, reserve_bonus)
	if weapon.ammo_in_magazine <= 0:
		var loaded: int = mini(weapon.magazine_size, weapon.reserve_ammo)
		weapon.ammo_in_magazine += loaded
		weapon.reserve_ammo -= loaded
	switch_weapon(weapon_id)
	_emit_weapon_state()

func has_weapon(weapon_id: String) -> bool:
	return bool(unlocked_weapons.get(weapon_id, false))

func get_current_weapon() -> WeaponData:
	return weapons.get(current_weapon_id, null)

func emit_current_state() -> void:
	_emit_weapon_state()

func is_current_automatic() -> bool:
	var weapon := get_current_weapon()
	return weapon != null and weapon.automatic

func _finish_reload() -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		reloading = false
		return
	var needed: int = weapon.magazine_size - weapon.ammo_in_magazine
	var moved: int = mini(needed, weapon.reserve_ammo)
	weapon.reserve_ammo -= moved
	weapon.ammo_in_magazine += moved
	reloading = false
	reload_finished.emit(weapon.id)
	_emit_weapon_state()

func _create_default_weapons() -> void:
	weapons["pistol"] = WeaponData.from_dictionary({
		"id": "pistol",
		"display_name": "手枪",
		"damage": 18,
		"fire_rate": 0.35,
		"magazine_size": 12,
		"ammo_in_magazine": 12,
		"reserve_ammo": 999,
		"reload_time": 1.0,
		"bullet_speed": 450,
		"automatic": false,
		"spread": 2
	})
	weapons["assault_rifle"] = WeaponData.from_dictionary({
		"id": "assault_rifle",
		"display_name": "突击步枪",
		"damage": 12,
		"fire_rate": 0.11,
		"magazine_size": 30,
		"ammo_in_magazine": 30,
		"reserve_ammo": 120,
		"reload_time": 1.4,
		"bullet_speed": 560,
		"automatic": true,
		"spread": 5
	})
	weapons["rpg"] = WeaponData.from_dictionary({
		"id": "rpg",
		"display_name": "RPG火箭筒",
		"damage": 78,
		"fire_rate": 0.9,
		"magazine_size": 1,
		"ammo_in_magazine": 0,
		"reserve_ammo": 0,
		"reload_time": 1.8,
		"bullet_speed": 360,
		"automatic": false,
		"spread": 0,
		"projectile_type": "rocket",
		"muzzle_flash_type": "explosion_small"
	})
	weapons["shotgun"] = WeaponData.from_dictionary({
		"id": "shotgun",
		"display_name": "战斗霰弹枪",
		"damage": 11,
		"pellets": 6,
		"fire_rate": 0.72,
		"magazine_size": 6,
		"ammo_in_magazine": 0,
		"reserve_ammo": 0,
		"reload_time": 1.6,
		"bullet_speed": 440,
		"automatic": false,
		"spread": 13
	})
	weapons["sniper_rifle"] = WeaponData.from_dictionary({
		"id": "sniper_rifle",
		"display_name": "反器材狙击枪",
		"damage": 86,
		"fire_rate": 1.05,
		"magazine_size": 5,
		"ammo_in_magazine": 0,
		"reserve_ammo": 0,
		"reload_time": 1.9,
		"bullet_speed": 820,
		"automatic": false,
		"spread": 0.4
	})
	unlocked_weapons["pistol"] = true
	unlocked_weapons["assault_rifle"] = true

func _emit_weapon_state() -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		return
	weapon_changed.emit(weapon.id, weapon.display_name)
	ammo_changed.emit(weapon.ammo_in_magazine, weapon.reserve_ammo, weapon.id)

func _get_projectile_parent() -> Node:
	if projectile_parent != null and is_instance_valid(projectile_parent):
		return projectile_parent
	if owner_body != null and owner_body.get_parent() != null:
		return owner_body.get_parent()
	return get_tree().current_scene

func _create_projectile(projectile_type: String) -> Node2D:
	if projectile_type == "rocket":
		return ROCKET_SCENE.instantiate()
	return BULLET_SCENE.instantiate()
