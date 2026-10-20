class_name EnemyBase
extends CharacterBody2D

signal died(enemy: Node)

const ENEMY_SHEET = preload("res://assets/sprites/enemies/enemy_soldiers_sheet_alpha.png")
const BULLET_SCENE = preload("res://scenes/weapons/Bullet.tscn")
const GRENADE_SCENE = preload("res://scenes/weapons/Grenade.tscn")
const PICKUP_SCENE = preload("res://scenes/pickups/PickupBase.tscn")

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HURT,
	DEAD
}

@export var max_hp := 45
@export var speed := 55.0
@export var patrol_distance := 150.0
@export var detection_range := 330.0
@export var attack_range := 260.0
@export var damage := 6
@export var attack_cooldown := 0.8

var hp := 45
var state := State.PATROL
var facing_direction := -1
var spawn_position := Vector2.ZERO
var attack_timer := 0.0
var hurt_timer := 0.0
var dead := false

var sprite: Sprite2D
var muzzle_point: Marker2D
var health_bar: Node2D
var frame_index := 0
var frame_time := 0.0
var current_animation := "idle"

func _ready() -> void:
	_setup_stats()
	hp = max_hp
	spawn_position = global_position
	add_to_group("enemies")
	add_to_group("damageables")
	collision_layer = Constants.LAYER_ENEMY
	collision_mask = Constants.LAYER_WORLD | Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_HAZARD
	_build_nodes()
	set_animation("idle")

func _setup_stats() -> void:
	pass

func get_team() -> String:
	return Constants.TEAM_ENEMY

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO, knockback_force: float = 0.0, source_team: String = Constants.TEAM_PLAYER) -> void:
	if dead or source_team == Constants.TEAM_ENEMY:
		return
	hp -= amount
	Utility.update_world_health_bar(health_bar, hp, max_hp)
	if hp <= 0:
		die()
		return
	var knock_dir: int = Utility.direction_from_delta(global_position.x - source_position.x)
	velocity.x += knock_dir * knockback_force
	state = State.HURT
	hurt_timer = 0.22
	set_animation("hurt")
	EffectSpawner.spawn_effect("blood", global_position + Vector2(0, -28), knock_dir)
	AudioManager.play_sfx("enemy_hit")

func die() -> void:
	if dead:
		return
	dead = true
	state = State.DEAD
	collision_layer = 0
	collision_mask = 0
	if health_bar != null:
		health_bar.visible = false
	set_animation("death")
	GameManager.add_kill()
	died.emit(self)
	_drop_pickup()
	AudioManager.play_sfx("enemy_die")

func _physics_process(delta: float) -> void:
	if dead:
		velocity.x = 0
		velocity.y += Constants.GRAVITY * delta
		move_and_slide()
		_animate(delta)
		return

	attack_timer = maxf(0.0, attack_timer - delta)
	velocity.y += Constants.GRAVITY * delta
	if hurt_timer > 0.0:
		hurt_timer -= delta
		state = State.HURT
		velocity.x = move_toward(velocity.x, 0.0, speed * 5.0 * delta)
	else:
		var player: Node2D = _find_player()
		if player == null:
			_patrol(delta)
		else:
			_update_ai(player, delta)
	move_and_slide()
	_update_facing()
	_update_animation()
	_animate(delta)

func _update_ai(player: Node2D, delta: float) -> void:
	var to_player: Vector2 = player.global_position - global_position
	var horizontal_distance: float = abs(to_player.x)
	var track_range := detection_range + (70.0 if state == State.CHASE or state == State.ATTACK else 0.0)
	if horizontal_distance <= track_range and abs(to_player.y) < 140.0:
		facing_direction = Utility.direction_from_delta(to_player.x)
		if horizontal_distance <= attack_range:
			state = State.ATTACK
			velocity.x = move_toward(velocity.x, 0.0, speed * 4.0 * delta)
			if attack_timer <= 0.0:
				attack_timer = attack_cooldown
				attack_target(player)
		else:
			state = State.CHASE
			velocity.x = facing_direction * speed
	else:
		_patrol(delta)

func attack_target(_player: Node2D) -> void:
	pass

func _patrol(_delta: float) -> void:
	state = State.PATROL
	var left_limit := spawn_position.x - patrol_distance
	var right_limit := spawn_position.x + patrol_distance
	if global_position.x <= left_limit:
		global_position.x = left_limit
		facing_direction = 1
	elif global_position.x >= right_limit:
		global_position.x = right_limit
		facing_direction = -1
	velocity.x = facing_direction * speed

func _build_nodes() -> void:
	Utility.make_rect_collision(self, Vector2(28, 48), Vector2(0, -24))
	sprite = Utility.make_sprite(self, ENEMY_SHEET, _get_frames("idle")[0], Vector2(0, -31), Vector2(0.68, 0.68))
	health_bar = Utility.make_world_health_bar(self, Vector2(34, 4), Vector2(0, -72))
	Utility.update_world_health_bar(health_bar, hp, max_hp)
	muzzle_point = Marker2D.new()
	muzzle_point.name = "MuzzlePoint"
	muzzle_point.position = Vector2(30, -32)
	add_child(muzzle_point)

func _fire_bullet(origin: Vector2, direction: Vector2, p_damage: int, speed_value: float, spread: float = 1.5) -> void:
	var bullet := BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = origin
	var shot_direction: Vector2 = direction.normalized().rotated(deg_to_rad(randf_range(-spread, spread)))
	bullet.setup(shot_direction, p_damage, Constants.TEAM_ENEMY, speed_value)
	EffectSpawner.spawn_effect("muzzle", origin, Utility.direction_from_delta(direction.x))
	AudioManager.play_sfx("shoot_rifle")

func _throw_grenade(origin: Vector2, direction: int) -> void:
	var grenade := GRENADE_SCENE.instantiate()
	grenade.fuse_time = 1.5
	grenade.explosion_damage = 28
	get_parent().add_child(grenade)
	grenade.global_position = origin
	grenade.setup(direction, Constants.TEAM_ENEMY)
	AudioManager.play_sfx("grenade_throw")

func _update_facing() -> void:
	if sprite == null:
		return
	sprite.flip_h = facing_direction < 0
	muzzle_point.position.x = 30 * facing_direction

func _update_animation() -> void:
	match state:
		State.HURT:
			set_animation("hurt")
		State.ATTACK:
			set_animation("attack")
		State.CHASE, State.PATROL:
			set_animation("walk")
		_:
			set_animation("idle")

func set_animation(name: String) -> void:
	if current_animation == name:
		return
	current_animation = name
	frame_index = 0
	frame_time = 0.0
	_apply_frame()

func _animate(delta: float) -> void:
	frame_time += delta
	if frame_time < 0.13:
		return
	frame_time = 0.0
	var frames := _get_frames(current_animation)
	if frames.is_empty():
		return
	frame_index = (frame_index + 1) % frames.size()
	_apply_frame()

func _apply_frame() -> void:
	var frames := _get_frames(current_animation)
	if frames.is_empty() or sprite == null:
		return
	sprite.region_rect = frames[frame_index % frames.size()]

func _get_frames(anim: String) -> Array:
	if _base_y() > 500:
		match anim:
			"walk":
				return [Rect2(243, 674, 58, 89), Rect2(341, 675, 65, 88), Rect2(449, 675, 67, 89), Rect2(549, 675, 74, 88), Rect2(644, 675, 73, 89), Rect2(750, 675, 76, 89)]
			"attack":
				return [Rect2(229, 779, 69, 87), Rect2(346, 780, 75, 86), Rect2(468, 779, 84, 87), Rect2(594, 776, 90, 90)]
			"hurt":
				return [Rect2(235, 878, 65, 88), Rect2(340, 882, 57, 84)]
			"death":
				return [Rect2(231, 979, 85, 57), Rect2(382, 987, 100, 48), Rect2(527, 987, 110, 45), Rect2(667, 995, 141, 41)]
			_:
				return [Rect2(227, 572, 56, 88), Rect2(338, 572, 55, 88), Rect2(449, 572, 55, 88), Rect2(555, 572, 55, 88)]
	match anim:
		"walk":
			return [Rect2(234, 150, 72, 88), Rect2(332, 149, 78, 91), Rect2(437, 149, 73, 90), Rect2(547, 149, 78, 89), Rect2(657, 150, 73, 89), Rect2(760, 150, 83, 87)]
		"attack":
			return [Rect2(235, 251, 79, 81), Rect2(347, 251, 82, 81), Rect2(458, 251, 90, 81), Rect2(613, 247, 91, 85)]
		"hurt":
			return [Rect2(233, 344, 61, 79), Rect2(338, 344, 54, 79)]
		"death":
			return [Rect2(232, 437, 81, 53), Rect2(382, 452, 100, 39), Rect2(535, 452, 107, 37), Rect2(687, 459, 147, 32)]
		_:
			return [Rect2(235, 43, 73, 90), Rect2(339, 44, 72, 89), Rect2(445, 44, 76, 89), Rect2(550, 44, 71, 89)]

func _base_y() -> int:
	return 34

func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	for node in players:
		if node is Node2D and is_instance_valid(node):
			return node
	return null

func _drop_pickup() -> void:
	var roll := randf()
	var pickup_type := ""
	if roll < 0.18:
		pickup_type = "health"
	elif roll < 0.48:
		pickup_type = "ammo"
	elif roll < 0.58:
		pickup_type = "grenade"
	if pickup_type == "":
		return
	var pickup := PICKUP_SCENE.instantiate()
	pickup.pickup_type = pickup_type
	pickup.global_position = global_position + Vector2(0, -18)
	get_parent().add_child(pickup)
