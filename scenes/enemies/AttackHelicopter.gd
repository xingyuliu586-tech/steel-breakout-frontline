extends Area2D

signal died(enemy: Node)

const HELICOPTER_TEXTURE = preload("res://assets/generated/attack_helicopter_alpha.png")
const BULLET_SCENE = preload("res://scenes/weapons/Bullet.tscn")

@export var max_hp := 160
@export var fire_rate := 0.12
@export var burst_size := 10
@export var burst_pause := 1.05
@export var detection_range := 760.0

var hp := 160
var age := 0.0
var center_position := Vector2.ZERO
var fire_timer := 0.0
var pause_timer := 0.6
var burst_count := 0
var facing_direction := -1
var dead := false
var sprite: Sprite2D
var health_bar: Node2D

func _ready() -> void:
	hp = max_hp
	center_position = global_position
	global_position += Vector2(470, -18)
	add_to_group("enemies")
	add_to_group("damageables")
	collision_layer = Constants.LAYER_ENEMY
	collision_mask = Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_HAZARD
	Utility.make_rect_collision(self, Vector2(166, 46), Vector2(0, 8))
	sprite = Sprite2D.new()
	sprite.texture = HELICOPTER_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.26, 0.26)
	sprite.z_index = 30
	add_child(sprite)
	health_bar = Utility.make_world_health_bar(self, Vector2(76, 5), Vector2(0, -46), Color(0.92, 0.14, 0.08, 1.0))
	Utility.update_world_health_bar(health_bar, hp, max_hp)

func get_team() -> String:
	return Constants.TEAM_ENEMY

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO, _knockback_force: float = 0.0, source_team: String = Constants.TEAM_PLAYER) -> void:
	if dead or source_team == Constants.TEAM_ENEMY:
		return
	hp -= amount
	Utility.update_world_health_bar(health_bar, hp, max_hp)
	facing_direction = Utility.direction_from_delta(source_position.x - global_position.x)
	EffectSpawner.spawn_effect("impact", global_position + Vector2(0, 8), facing_direction)
	AudioManager.play_sfx("metal_hit")
	if hp <= 0:
		die()

func die() -> void:
	if dead:
		return
	dead = true
	collision_layer = 0
	collision_mask = 0
	if health_bar != null:
		health_bar.visible = false
	EffectSpawner.spawn_effect("explosion_medium", global_position)
	EffectSpawner.spawn_effect("smoke", global_position + Vector2(0, 12))
	AudioManager.play_sfx("explosion")
	GameManager.add_score(450)
	died.emit(self)
	queue_free()

func _physics_process(delta: float) -> void:
	if dead:
		return
	age += delta
	var hover_target: Vector2 = Vector2(center_position.x + sin(age * 0.72) * 210.0, center_position.y + sin(age * 1.55) * 15.0)
	global_position = global_position.move_toward(hover_target, 145.0 * delta)
	var player: Node2D = _find_player()
	if player == null:
		return
	var target_position: Vector2 = player.global_position + Vector2(0, -30)
	var to_player: Vector2 = target_position - global_position
	if to_player.length() > detection_range:
		return
	facing_direction = Utility.direction_from_delta(to_player.x)
	sprite.flip_h = facing_direction > 0
	if pause_timer > 0.0:
		pause_timer -= delta
		return
	fire_timer -= delta
	if fire_timer <= 0.0:
		_fire_at(target_position)
		fire_timer = fire_rate
		burst_count += 1
		if burst_count >= burst_size:
			burst_count = 0
			pause_timer = burst_pause

func _fire_at(target_position: Vector2) -> void:
	var muzzle: Vector2 = global_position + Vector2(112.0 * float(facing_direction), 26.0)
	var direction: Vector2 = (target_position - muzzle).normalized()
	var bullet: Node2D = BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = muzzle
	bullet.setup(direction, 4, Constants.TEAM_ENEMY, 520.0)
	EffectSpawner.spawn_effect("muzzle", muzzle, facing_direction)
	AudioManager.play_sfx("shoot_rifle")

func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group("player"):
		if node is Node2D and is_instance_valid(node):
			return node
	return null
