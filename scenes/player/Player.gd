extends CharacterBody2D

signal stats_changed(hp: int, max_hp: int, armor: int, max_armor: int, stamina: int, max_stamina: int, grenades: int)
signal ammo_changed(ammo_in_magazine: int, reserve_ammo: int, weapon_id: String)
signal weapon_changed(weapon_id: String, display_name: String)
signal died

const PLAYER_SHEET = preload("res://assets/sprites/player/player_soldier_sheet_alpha.png")
const PLAYER_WEAPON_SHEET = preload("res://assets/generated/player_weapon_variants_sheet_alpha.png")
const PLAYER_AIM_SHEET = preload("res://assets/generated/player_mouse_aim_variants_sheet_alpha.png")
const PLAYER_SPECIAL_AIM_SHEET = preload("res://assets/generated/player_special_weapon_aim_sheet_alpha.png")
const PLAYER_SPECIAL_MOTION_SHEET = preload("res://assets/generated/player_special_weapon_motion_sheet_alpha.png")
const PLAYER_RUNNING_AIM_SHEET = preload("res://assets/generated/player_running_aim_sheet_alpha.png")
const GRENADE_SCENE = preload("res://scenes/weapons/Grenade.tscn")
const WEAPON_SYSTEM_SCRIPT = preload("res://scenes/weapons/Weapon.gd")

const WEAPON_CELL_SIZE = Vector2(180, 128)
const WEAPON_BASELINE_Y := 118.0
const AIM_CELL_SIZE = Vector2(270, 280)
const AIM_SPRITE_SCALE = Vector2(0.34, 0.34)
const AIM_SPRITE_POSITION = Vector2(0, -45)
const RIFLE_RUN_SPRITE_SCALE = Vector2(0.515, 0.515)
const RIFLE_RUN_SPRITE_POSITION = Vector2(0, -60)

@export var max_hp := 180
@export var max_armor := 80
@export var max_stamina := 100
@export var walk_speed := 110.0
@export var run_speed := 140.0
@export var jump_velocity := -280.0
@export var max_grenades := 5

var hp := 180
var armor := 30
var stamina := 100
var grenades := 2
var facing_direction := 1
var state := PlayerStateMachine.State.IDLE
var dead := false
var invincible := false
var grenade_selected := false
var aim_direction := Vector2.RIGHT
var aim_column := 2

var sprite: Sprite2D
var weapon_visual_id := "pistol"
var muzzle_point: Marker2D
var grenade_throw_point: Marker2D
var weapon_system: WeaponSystem
var invincible_timer: Timer
var frame_index := 0
var frame_time := 0.0
var current_animation := "idle"
var projectile_parent: Node

var animation_frames := {
	"idle": [Rect2(235, 14, 74, 97), Rect2(358, 14, 74, 97), Rect2(480, 13, 73, 98), Rect2(598, 13, 74, 98)],
	"run": [Rect2(230, 125, 84, 95), Rect2(353, 125, 87, 95), Rect2(476, 125, 84, 94), Rect2(598, 125, 84, 95), Rect2(712, 125, 88, 95), Rect2(840, 125, 85, 95), Rect2(963, 125, 86, 95), Rect2(1087, 125, 86, 95)],
	"jump": [Rect2(225, 233, 89, 95), Rect2(356, 233, 75, 92), Rect2(487, 233, 68, 92), Rect2(608, 247, 75, 81)],
	"crouch": [Rect2(232, 346, 76, 75), Rect2(347, 346, 75, 75)],
	"shoot": [Rect2(233, 433, 81, 94), Rect2(357, 434, 96, 93), Rect2(485, 434, 111, 93), Rect2(620, 433, 112, 94)],
	"crouch_shoot": [Rect2(232, 540, 82, 72), Rect2(360, 541, 111, 71)],
	"reload": [Rect2(232, 623, 74, 98), Rect2(361, 623, 67, 98), Rect2(491, 624, 68, 97), Rect2(608, 624, 70, 97), Rect2(725, 624, 65, 97), Rect2(837, 624, 72, 97)],
	"throw_grenade": [Rect2(224, 734, 75, 94), Rect2(350, 736, 90, 92), Rect2(493, 735, 87, 93), Rect2(620, 735, 79, 93), Rect2(773, 735, 71, 93), Rect2(891, 734, 75, 93)],
	"hurt": [Rect2(224, 840, 70, 95), Rect2(355, 843, 57, 92), Rect2(469, 848, 54, 87)],
	"death": [Rect2(227, 943, 69, 94), Rect2(353, 969, 80, 71), Rect2(477, 991, 95, 53), Rect2(623, 995, 107, 49), Rect2(769, 1005, 138, 41), Rect2(945, 1005, 163, 39)]
}

func _ready() -> void:
	Utility.configure_input_actions()
	add_to_group("player")
	add_to_group("damageables")
	collision_layer = Constants.LAYER_PLAYER
	collision_mask = Constants.LAYER_WORLD | Constants.LAYER_ENEMY_PROJECTILE | Constants.LAYER_PICKUP | Constants.LAYER_HAZARD | Constants.LAYER_INTERACTION
	hp = max_hp
	armor = 30
	stamina = max_stamina
	_build_nodes()
	weapon_system.setup(self, projectile_parent)
	_emit_all_stats()

func setup_projectile_parent(parent: Node) -> void:
	projectile_parent = parent
	if weapon_system != null:
		weapon_system.setup(self, projectile_parent)

func emit_current_status() -> void:
	_emit_all_stats()
	if weapon_system != null:
		weapon_system.emit_current_state()

func get_team() -> String:
	return Constants.TEAM_PLAYER

func _physics_process(delta: float) -> void:
	if dead:
		velocity.x = move_toward(velocity.x, 0.0, run_speed * delta)
		velocity.y += Constants.GRAVITY * delta
		move_and_slide()
		return

	_handle_movement(delta)
	_update_aim_from_mouse()
	_handle_weapon_inputs()
	_update_animation_state()
	_animate(delta)

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO, knockback_force: float = 0.0, source_team: String = Constants.TEAM_ENEMY) -> void:
	if dead or invincible or source_team == Constants.TEAM_PLAYER:
		return
	var remaining: int = amount
	if armor > 0:
		var absorbed: int = mini(armor, remaining)
		armor -= absorbed
		remaining -= absorbed
	hp = maxi(0, hp - remaining)
	invincible = true
	invincible_timer.start(0.65)
	var knock_dir: int = Utility.direction_from_delta(global_position.x - source_position.x)
	velocity.x += knock_dir * knockback_force
	set_animation("hurt")
	EffectSpawner.spawn_effect("blood", global_position + Vector2(0, -32), knock_dir)
	AudioManager.play_sfx("player_hit")
	_emit_all_stats()
	if hp <= 0:
		die()

func heal(amount: int) -> void:
	if dead:
		return
	hp = mini(max_hp, hp + amount)
	_emit_all_stats()

func add_armor(amount: int) -> void:
	armor = mini(max_armor, armor + amount)
	_emit_all_stats()

func add_grenades(amount: int) -> void:
	grenades = mini(max_grenades, grenades + amount)
	_emit_all_stats()

func add_ammo(amount: int) -> void:
	if weapon_system != null:
		weapon_system.add_reserve_ammo(amount)

func unlock_weapon(weapon_id: String, ammo_amount: int = 0) -> void:
	grenade_selected = false
	if weapon_system != null:
		weapon_system.unlock_weapon(weapon_id, ammo_amount)
		_set_weapon_visual(weapon_id)

func die() -> void:
	if dead:
		return
	dead = true
	state = PlayerStateMachine.State.DEAD
	set_animation("death")
	AudioManager.play_sfx("player_die")
	died.emit()

func _build_nodes() -> void:
	Utility.make_rect_collision(self, Vector2(28, 50), Vector2(0, -25))
	sprite = Utility.make_sprite(self, PLAYER_SHEET, animation_frames["idle"][0], Vector2(0, -32), Vector2(0.68, 0.68))
	muzzle_point = Marker2D.new()
	muzzle_point.name = "MuzzlePoint"
	muzzle_point.position = Vector2(33, -34)
	add_child(muzzle_point)
	grenade_throw_point = Marker2D.new()
	grenade_throw_point.name = "GrenadeThrowPoint"
	grenade_throw_point.position = Vector2(18, -44)
	add_child(grenade_throw_point)
	invincible_timer = Timer.new()
	invincible_timer.one_shot = true
	add_child(invincible_timer)
	invincible_timer.timeout.connect(func() -> void: invincible = false)
	weapon_system = WEAPON_SYSTEM_SCRIPT.new()
	add_child(weapon_system)
	weapon_system.ammo_changed.connect(func(mag: int, reserve: int, id: String) -> void: ammo_changed.emit(mag, reserve, id))
	weapon_system.weapon_changed.connect(func(id: String, label: String) -> void:
		if not grenade_selected:
			_set_weapon_visual(id)
		weapon_changed.emit(id, label)
	)
	_set_weapon_visual("pistol")

func _handle_movement(delta: float) -> void:
	var input_dir: float = Input.get_axis("move_left", "move_right")
	var crouching: bool = Input.is_action_pressed("crouch") and is_on_floor()
	if input_dir != 0:
		facing_direction = Utility.direction_from_delta(input_dir)
		sprite.flip_h = facing_direction < 0
		muzzle_point.position.x = 33 * facing_direction
		grenade_throw_point.position.x = 18 * facing_direction
	var target_speed: float = run_speed if not crouching else walk_speed * 0.35
	velocity.x = input_dir * target_speed
	if not is_on_floor():
		velocity.y += Constants.GRAVITY * delta
	elif Input.is_action_just_pressed("jump") and not crouching:
		velocity.y = jump_velocity
		EffectSpawner.spawn_effect("smoke", global_position + Vector2(0, -4), facing_direction)
	move_and_slide()

	if abs(input_dir) > 0.05 and is_on_floor():
		stamina = maxi(0, stamina - int(12 * delta))
	else:
		stamina = mini(max_stamina, stamina + int(18 * delta))
	_emit_all_stats()

func _handle_weapon_inputs() -> void:
	if Input.is_action_just_pressed("switch_weapon_1"):
		_select_weapon("pistol")
	if Input.is_action_just_pressed("switch_weapon_2"):
		_select_weapon("assault_rifle")
	if Input.is_action_just_pressed("switch_weapon_3"):
		_select_grenade()
	if Input.is_action_just_pressed("switch_weapon_4"):
		_select_weapon("rpg")
	if Input.is_action_just_pressed("switch_weapon_5"):
		_select_weapon("shotgun")
	if Input.is_action_just_pressed("switch_weapon_6"):
		_select_weapon("sniper_rifle")
	if Input.is_action_just_pressed("reload"):
		weapon_system.start_reload()

	if grenade_selected:
		if Input.is_action_just_pressed("shoot"):
			_throw_grenade()
	else:
		var wants_shoot: bool = Input.is_action_pressed("shoot") if weapon_system.is_current_automatic() else Input.is_action_just_pressed("shoot")
		if wants_shoot:
			var direction := _get_shoot_direction()
			if weapon_system.try_fire(muzzle_point.global_position, direction, Constants.TEAM_PLAYER):
				set_animation("crouch_shoot" if Input.is_action_pressed("crouch") and is_on_floor() else "shoot")

	if Input.is_action_just_pressed("throw_grenade"):
		_throw_grenade()

func _select_weapon(weapon_id: String) -> void:
	if weapon_system != null and not weapon_system.has_weapon(weapon_id):
		return
	grenade_selected = false
	_set_weapon_visual(weapon_id)
	weapon_system.switch_weapon(weapon_id)
	weapon_system.emit_current_state()

func _select_grenade() -> void:
	grenade_selected = grenades > 0
	if grenade_selected:
		_set_weapon_visual("grenade")
		weapon_changed.emit("grenade", "手雷就绪")

func _throw_grenade() -> void:
	if grenades <= 0:
		grenade_selected = false
		_set_weapon_visual(weapon_system.current_weapon_id)
		weapon_system.emit_current_state()
		return
	grenades -= 1
	var grenade := GRENADE_SCENE.instantiate()
	(projectile_parent if projectile_parent != null else get_parent()).add_child(grenade)
	grenade.global_position = grenade_throw_point.global_position
	grenade.setup(facing_direction, Constants.TEAM_PLAYER)
	set_animation("throw_grenade")
	AudioManager.play_sfx("grenade_throw")
	_emit_all_stats()
	if grenades <= 0:
		grenade_selected = false
		weapon_system.emit_current_state()
	_set_weapon_visual("grenade" if grenade_selected else weapon_system.current_weapon_id)

func _update_aim_from_mouse() -> void:
	var aim_origin: Vector2 = global_position + Vector2(0, -34)
	var raw_direction: Vector2 = get_global_mouse_position() - aim_origin
	if raw_direction.length() < 6.0:
		raw_direction = Vector2(float(facing_direction), 0.0)
	aim_direction = raw_direction.normalized()
	if abs(aim_direction.x) > 0.08:
		facing_direction = Utility.direction_from_delta(aim_direction.x)
	if sprite != null:
		sprite.flip_h = facing_direction < 0
	var new_aim_column: int = _aim_column_for_direction(aim_direction)
	if new_aim_column != aim_column:
		aim_column = new_aim_column
		_apply_frame()
	var muzzle_x: float = 44.0 + maxf(0.0, aim_direction.x * float(facing_direction)) * 12.0
	var muzzle_y: float = -42.0 + clampf(aim_direction.y * 34.0, -40.0, 30.0)
	muzzle_point.position = Vector2(muzzle_x * float(facing_direction), muzzle_y)
	grenade_throw_point.position = Vector2(18.0 * float(facing_direction), -44.0 + clampf(aim_direction.y * 14.0, -10.0, 12.0))

func _get_shoot_direction() -> Vector2:
	var direction := get_global_mouse_position() - muzzle_point.global_position
	if direction.length() < 6.0:
		return Vector2(float(facing_direction), 0.0)
	return direction.normalized()

func _set_weapon_visual(weapon_id: String) -> void:
	weapon_visual_id = weapon_id
	_apply_frame()

func _update_animation_state() -> void:
	if current_animation in ["shoot", "crouch_shoot", "throw_grenade", "hurt"] and frame_time < 0.09:
		return
	if not is_on_floor():
		state = PlayerStateMachine.State.JUMP if velocity.y < 0 else PlayerStateMachine.State.FALL
	elif Input.is_action_pressed("crouch"):
		state = PlayerStateMachine.State.CROUCH
	elif abs(velocity.x) > 4.0:
		state = PlayerStateMachine.State.RUN
	else:
		state = PlayerStateMachine.State.IDLE
	set_animation(PlayerStateMachine.to_animation_name(state))

func set_animation(name: String) -> void:
	if not animation_frames.has(name):
		name = "idle"
	if current_animation == name:
		return
	current_animation = name
	frame_index = 0
	frame_time = 0.0
	_apply_frame()

func _animate(delta: float) -> void:
	frame_time += delta
	if frame_time < 0.11:
		return
	frame_time = 0.0
	var frames: Array = animation_frames.get(current_animation, animation_frames["idle"])
	if frames.is_empty():
		return
	frame_index = (frame_index + 1) % frames.size()
	_apply_frame()

func _apply_frame() -> void:
	if weapon_visual_id == "assault_rifle" and current_animation == "run" and sprite != null:
		sprite.texture = PLAYER_RUNNING_AIM_SHEET
		sprite.scale = RIFLE_RUN_SPRITE_SCALE
		sprite.position = RIFLE_RUN_SPRITE_POSITION
		var run_row := frame_index % 2
		sprite.region_rect = Rect2(AIM_CELL_SIZE.x * float(aim_column), AIM_CELL_SIZE.y * float(run_row), AIM_CELL_SIZE.x, AIM_CELL_SIZE.y)
		sprite.flip_h = facing_direction < 0
		return
	if _is_special_weapon() and _uses_mouse_aim_sprite(current_animation) and sprite != null:
		sprite.texture = PLAYER_SPECIAL_AIM_SHEET
		sprite.scale = AIM_SPRITE_SCALE
		sprite.position = AIM_SPRITE_POSITION
		sprite.region_rect = _get_special_aim_frame()
		sprite.flip_h = facing_direction < 0
		return
	var special_frames := _get_special_motion_frames(current_animation)
	if not special_frames.is_empty() and sprite != null:
		sprite.texture = PLAYER_SPECIAL_MOTION_SHEET
		sprite.scale = Vector2.ONE
		sprite.position = Vector2(0, -(WEAPON_BASELINE_Y - WEAPON_CELL_SIZE.y * 0.5))
		sprite.region_rect = special_frames[frame_index % special_frames.size()]
		sprite.flip_h = facing_direction < 0
		return
	if _uses_mouse_aim_sprite(current_animation) and sprite != null:
		sprite.texture = PLAYER_AIM_SHEET
		sprite.scale = AIM_SPRITE_SCALE
		sprite.position = AIM_SPRITE_POSITION
		sprite.region_rect = _get_mouse_aim_frame()
		sprite.flip_h = facing_direction < 0
		return
	var weapon_frames := _get_weapon_variant_frames(current_animation)
	if not weapon_frames.is_empty() and sprite != null:
		sprite.texture = PLAYER_WEAPON_SHEET
		sprite.scale = Vector2.ONE
		sprite.position = Vector2(0, -(WEAPON_BASELINE_Y - WEAPON_CELL_SIZE.y * 0.5))
		sprite.region_rect = weapon_frames[frame_index % weapon_frames.size()]
		sprite.flip_h = facing_direction < 0
		return
	var frames: Array = animation_frames.get(current_animation, animation_frames["idle"])
	if frames.is_empty() or sprite == null:
		return
	sprite.texture = PLAYER_SHEET
	sprite.scale = Vector2(0.68, 0.68)
	sprite.position = Vector2(0, -32)
	sprite.region_rect = frames[frame_index % frames.size()]
	sprite.flip_h = facing_direction < 0

func _get_weapon_variant_frames(anim: String) -> Array:
	if anim == "death":
		return []
	var row := 0
	match weapon_visual_id:
		"assault_rifle":
			row = 1
		"rpg":
			row = 3
		"grenade":
			row = 2
		_:
			row = 0
	var y := row * int(WEAPON_CELL_SIZE.y)
	match anim:
		"run":
			return [
				Rect2(WEAPON_CELL_SIZE.x, y, WEAPON_CELL_SIZE.x, WEAPON_CELL_SIZE.y),
				Rect2(WEAPON_CELL_SIZE.x * 2.0, y, WEAPON_CELL_SIZE.x, WEAPON_CELL_SIZE.y)
			]
		"hurt":
			return [Rect2(0, y, WEAPON_CELL_SIZE.x, WEAPON_CELL_SIZE.y)]
		"shoot", "crouch_shoot", "throw_grenade":
			return [Rect2(WEAPON_CELL_SIZE.x * 3.0, y, WEAPON_CELL_SIZE.x, WEAPON_CELL_SIZE.y)]
		_:
			return [Rect2(0, y, WEAPON_CELL_SIZE.x, WEAPON_CELL_SIZE.y)]

func _get_special_motion_frames(anim: String) -> Array:
	if not _is_special_weapon() or anim == "death":
		return []
	var row := 0 if weapon_visual_id == "shotgun" else 1
	var y := row * int(WEAPON_CELL_SIZE.y)
	match anim:
		"run":
			return [
				Rect2(WEAPON_CELL_SIZE.x, y, WEAPON_CELL_SIZE.x, WEAPON_CELL_SIZE.y),
				Rect2(WEAPON_CELL_SIZE.x * 2.0, y, WEAPON_CELL_SIZE.x, WEAPON_CELL_SIZE.y),
				Rect2(WEAPON_CELL_SIZE.x * 3.0, y, WEAPON_CELL_SIZE.x, WEAPON_CELL_SIZE.y)
			]
		"shoot", "crouch_shoot":
			return [Rect2(WEAPON_CELL_SIZE.x * 4.0, y, WEAPON_CELL_SIZE.x, WEAPON_CELL_SIZE.y)]
		_:
			return [Rect2(0, y, WEAPON_CELL_SIZE.x, WEAPON_CELL_SIZE.y)]

func _uses_mouse_aim_sprite(anim: String) -> bool:
	if weapon_visual_id == "grenade":
		return false
	if anim in ["hurt", "death", "throw_grenade", "run", "jump", "crouch", "reload"]:
		return false
	if weapon_visual_id not in ["pistol", "assault_rifle", "rpg", "shotgun", "sniper_rifle"]:
		return false
	return anim in ["idle", "shoot", "crouch_shoot"]

func _is_special_weapon() -> bool:
	return weapon_visual_id in ["shotgun", "sniper_rifle"]

func _get_special_aim_frame() -> Rect2:
	var row := 0 if weapon_visual_id == "shotgun" else 1
	return Rect2(AIM_CELL_SIZE.x * float(aim_column), AIM_CELL_SIZE.y * float(row), AIM_CELL_SIZE.x, AIM_CELL_SIZE.y)

func _get_mouse_aim_frame() -> Rect2:
	var row := 0
	match weapon_visual_id:
		"assault_rifle":
			row = 1
		"rpg":
			row = 2
		_:
			row = 0
	return Rect2(AIM_CELL_SIZE.x * float(aim_column), AIM_CELL_SIZE.y * float(row), AIM_CELL_SIZE.x, AIM_CELL_SIZE.y)

func _aim_column_for_direction(direction: Vector2) -> int:
	if direction.y <= -0.68:
		return 0
	if direction.y <= -0.22:
		return 1
	if direction.y < 0.22:
		return 2
	if direction.y < 0.58:
		return 3
	return 4

func _emit_all_stats() -> void:
	stats_changed.emit(hp, max_hp, armor, max_armor, stamina, max_stamina, grenades)
