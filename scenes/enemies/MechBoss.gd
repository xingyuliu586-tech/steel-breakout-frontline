extends CharacterBody2D

signal died(enemy: Node)

const MECH_TEXTURE = preload("res://assets/generated/mech_boss_action_sheet_alpha.png")
const BULLET_SCENE = preload("res://scenes/weapons/MechRound.tscn")
const ROCKET_SCENE = preload("res://scenes/weapons/MechMissile.tscn")

@export var max_hp := 360
@export var walk_speed := 32.0
@export var detection_range := 760.0
@export var preferred_range := 285.0

var hp := 360
var facing_direction := -1
var bullet_timer := 0.0
var rocket_timer := 1.2
var dead := false
var sprite: Sprite2D
var health_bar: Node2D
var walk_frame := 0
var walk_frame_time := 0.0
var action_frame_time := 0.0

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	add_to_group("damageables")
	collision_layer = Constants.LAYER_ENEMY
	collision_mask = Constants.LAYER_WORLD | Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_HAZARD
	Utility.make_rect_collision(self, Vector2(86, 134), Vector2(0, -67))
	sprite = Sprite2D.new()
	sprite.texture = MECH_TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 460, 430)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.45, 0.45)
	sprite.position = Vector2(0, -96)
	sprite.z_index = 22
	add_child(sprite)
	health_bar = Utility.make_world_health_bar(self, Vector2(100, 7), Vector2(0, -188), Color(0.92, 0.12, 0.08, 1.0))
	Utility.update_world_health_bar(health_bar, hp, max_hp)

func get_team() -> String:
	return Constants.TEAM_ENEMY

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO, _knockback_force: float = 0.0, source_team: String = Constants.TEAM_PLAYER) -> void:
	if dead or source_team == Constants.TEAM_ENEMY:
		return
	hp -= amount
	Utility.update_world_health_bar(health_bar, hp, max_hp)
	facing_direction = Utility.direction_from_delta(source_position.x - global_position.x)
	EffectSpawner.spawn_effect("impact", global_position + Vector2(0, -92), facing_direction)
	AudioManager.play_sfx("metal_hit")
	sprite.modulate = Color(1.0, 0.72, 0.62, 1.0)
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		if sprite != null:
			sprite.modulate = Color.WHITE
	)
	if hp <= 0:
		die()
	elif hp <= max_hp / 2:
		sprite.region_rect = Rect2(460, 430, 460, 430)

func die() -> void:
	if dead:
		return
	dead = true
	collision_layer = 0
	collision_mask = 0
	if health_bar != null:
		health_bar.visible = false
	EffectSpawner.spawn_effect("explosion_medium", global_position + Vector2(-26, -118))
	EffectSpawner.spawn_effect("explosion_medium", global_position + Vector2(34, -76))
	EffectSpawner.spawn_effect("smoke", global_position + Vector2(0, -88))
	sprite.region_rect = Rect2(920, 430, 460, 430)
	AudioManager.play_sfx("explosion")
	GameManager.add_score(900)
	died.emit(self)
	get_tree().create_timer(2.2).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if dead:
		return
	velocity.y += Constants.GRAVITY * delta
	var player: Node2D = _find_player()
	if player != null:
		_update_ai(player, delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * delta)
	move_and_slide()
	action_frame_time = maxf(0.0, action_frame_time - delta)
	if action_frame_time > 0.0:
		return
	if hp <= max_hp / 2:
		sprite.region_rect = Rect2(460, 430, 460, 430)
	elif absf(velocity.x) > 1.0:
		walk_frame_time += delta
		if walk_frame_time >= 0.18:
			walk_frame_time = 0.0
			walk_frame = 1 - walk_frame
			sprite.region_rect = Rect2(460.0 + float(walk_frame) * 460.0, 0, 460, 430)
	else:
		sprite.region_rect = Rect2(0, 0, 460, 430)

func _update_ai(player: Node2D, delta: float) -> void:
	var target: Vector2 = player.global_position + Vector2(0, -30)
	var to_player: Vector2 = target - global_position
	var distance_x: float = absf(to_player.x)
	if distance_x > detection_range:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * delta)
		return
	facing_direction = Utility.direction_from_delta(to_player.x)
	sprite.flip_h = facing_direction < 0
	if distance_x > preferred_range:
		velocity.x = facing_direction * walk_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 4.0 * delta)
	bullet_timer -= delta
	rocket_timer -= delta
	if bullet_timer <= 0.0:
		_fire_bullet(target)
		bullet_timer = 0.24
	if rocket_timer <= 0.0:
		_fire_rocket(target)
		rocket_timer = 1.65

func _fire_bullet(target: Vector2) -> void:
	var muzzle: Vector2 = global_position + Vector2(84.0 * float(facing_direction), -100.0)
	var direction: Vector2 = (target - muzzle).normalized().rotated(deg_to_rad(randf_range(-3.0, 3.0)))
	var bullet: Node2D = BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = muzzle
	bullet.setup(direction, 12, Constants.TEAM_ENEMY, 540.0)
	sprite.region_rect = Rect2(1380, 0, 460, 430)
	action_frame_time = 0.16
	EffectSpawner.spawn_effect("muzzle", muzzle, facing_direction)
	AudioManager.play_sfx("shoot_rifle")

func _fire_rocket(target: Vector2) -> void:
	var muzzle: Vector2 = global_position + Vector2(92.0 * float(facing_direction), -92.0)
	var direction: Vector2 = (target - muzzle).normalized()
	var rocket: Node2D = ROCKET_SCENE.instantiate()
	get_parent().add_child(rocket)
	rocket.global_position = muzzle
	rocket.setup(direction, 44, Constants.TEAM_ENEMY, 330.0)
	sprite.region_rect = Rect2(0, 430, 460, 430)
	action_frame_time = 0.24
	AudioManager.play_sfx("grenade_throw")

func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group("player"):
		if node is Node2D and is_instance_valid(node):
			return node
	return null
