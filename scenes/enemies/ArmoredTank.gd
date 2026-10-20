extends CharacterBody2D

signal died(enemy: Node)

const TANK_SHEET = preload("res://assets/generated/heavy_tank_sheet_alpha.png")
const BULLET_SCENE = preload("res://scenes/weapons/Bullet.tscn")
const TANK_SHELL_SCENE = preload("res://scenes/weapons/TankShell.tscn")

@export var max_hp := 260
@export var move_speed := 24.0
@export var detection_range := 680.0
@export var preferred_range := 300.0
@export var rocket_enabled := true

var hp := 260
var facing_direction := -1
var bullet_timer := 0.0
var rocket_timer := 1.2
var destroyed := false
var sprite: Sprite2D
var health_bar: Node2D

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	add_to_group("damageables")
	collision_layer = Constants.LAYER_ENEMY
	collision_mask = Constants.LAYER_WORLD | Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_HAZARD
	Utility.make_rect_collision(self, Vector2(190, 68), Vector2(0, -34))
	sprite = Utility.make_sprite(self, TANK_SHEET, Rect2(0, 0, 460, 240), Vector2(0, -58), Vector2(0.50, 0.50))
	sprite.z_index = 18
	health_bar = Utility.make_world_health_bar(self, Vector2(150, 7), Vector2(0, -125), Color(0.92, 0.14, 0.08, 1.0))
	Utility.update_world_health_bar(health_bar, hp, max_hp)

func get_team() -> String:
	return Constants.TEAM_ENEMY

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO, _knockback_force: float = 0.0, source_team: String = Constants.TEAM_PLAYER) -> void:
	if destroyed or source_team == Constants.TEAM_ENEMY:
		return
	hp = maxi(0, hp - amount)
	Utility.update_world_health_bar(health_bar, hp, max_hp)
	facing_direction = Utility.direction_from_delta(source_position.x - global_position.x)
	EffectSpawner.spawn_effect("impact", global_position + Vector2(0, -30), facing_direction)
	AudioManager.play_sfx("metal_hit")
	sprite.modulate = Color(1.0, 0.72, 0.60, 1.0)
	get_tree().create_timer(0.07).timeout.connect(func() -> void:
		if sprite != null:
			sprite.modulate = Color.WHITE
	)
	if hp <= 0:
		die()
	elif hp <= max_hp / 2:
		sprite.region_rect = Rect2(920, 0, 460, 240)

func die() -> void:
	if destroyed:
		return
	destroyed = true
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	if health_bar != null:
		health_bar.visible = false
	if sprite != null:
		sprite.region_rect = Rect2(1380, 0, 460, 240)
		sprite.position = Vector2(0, -45)
	EffectSpawner.spawn_effect("explosion_medium", global_position + Vector2(-30, -30))
	EffectSpawner.spawn_effect("explosion_medium", global_position + Vector2(28, -24))
	EffectSpawner.spawn_effect("smoke", global_position + Vector2(0, -42))
	AudioManager.play_sfx("explosion")
	GameManager.add_score(650)
	died.emit(self)

func _physics_process(delta: float) -> void:
	if destroyed:
		return
	velocity.y += Constants.GRAVITY * delta
	var player: Node2D = _find_player()
	if player == null:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
		move_and_slide()
		return
	var target: Vector2 = player.global_position + Vector2(0, -24)
	var to_player: Vector2 = target - global_position
	var distance_x: float = absf(to_player.x)
	if distance_x <= detection_range and absf(to_player.y) < 190.0:
		facing_direction = Utility.direction_from_delta(to_player.x)
		sprite.flip_h = facing_direction < 0
		if distance_x > preferred_range:
			velocity.x = facing_direction * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, move_speed * 4.0 * delta)
		bullet_timer -= delta
		rocket_timer -= delta
		if bullet_timer <= 0.0:
			_fire_bullet(target)
			bullet_timer = 0.30
		if rocket_enabled and rocket_timer <= 0.0:
			_fire_shell(target)
			rocket_timer = 2.4
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta)
	move_and_slide()

func _fire_bullet(target: Vector2) -> void:
	var muzzle := global_position + Vector2(58.0 * float(facing_direction), -39.0)
	var direction := (target - muzzle).normalized().rotated(deg_to_rad(randf_range(-2.0, 2.0)))
	var bullet: Node2D = BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = muzzle
	bullet.setup(direction, 7, Constants.TEAM_ENEMY, 520.0)
	EffectSpawner.spawn_effect("muzzle", muzzle, facing_direction)
	AudioManager.play_sfx("shoot_rifle")

func _fire_shell(target: Vector2) -> void:
	var muzzle := global_position + Vector2(112.0 * float(facing_direction), -72.0)
	var shell: Node2D = TANK_SHELL_SCENE.instantiate()
	get_parent().add_child(shell)
	shell.global_position = muzzle
	shell.setup((target - muzzle).normalized(), 55, Constants.TEAM_ENEMY, 390.0)
	sprite.region_rect = Rect2(460, 0, 460, 240)
	get_tree().create_timer(0.16).timeout.connect(func() -> void:
		if sprite != null and not destroyed:
			sprite.region_rect = Rect2(920 if hp <= max_hp / 2 else 0, 0, 460, 240)
	)
	EffectSpawner.spawn_effect("explosion_small", muzzle, facing_direction)
	AudioManager.play_sfx("explosion")

func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group("player"):
		if node is Node2D and is_instance_valid(node):
			return node
	return null
