extends StaticBody2D

signal died(turret: Node)

const OBJECT_SHEET = preload("res://assets/sprites/objects/defense_objectives_sheet_alpha.png")
const BULLET_SCENE = preload("res://scenes/weapons/Bullet.tscn")
const WRECK_TEXTURE = preload("res://assets/generated/turret_wreck_alpha.png")

@export var max_hp := 80
@export var detection_range := 370.0
@export var fire_rate := 0.15
@export var burst_size := 5
@export var burst_pause := 0.9

var hp := 80
var facing_direction := -1
var fire_timer := 0.0
var burst_count := 0
var pause_timer := 0.0
var destroyed := false
var sprite: Sprite2D
var muzzle_point: Marker2D
var health_bar: Node2D

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	add_to_group("damageables")
	collision_layer = Constants.LAYER_ENEMY
	collision_mask = Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_HAZARD
	Utility.make_rect_collision(self, Vector2(54, 46), Vector2(0, -24))
	sprite = Utility.make_sprite(self, OBJECT_SHEET, Rect2(250, 74, 90, 82), Vector2(0, -36), Vector2(0.75, 0.75))
	health_bar = Utility.make_world_health_bar(self, Vector2(46, 5), Vector2(0, -82), Color(0.94, 0.18, 0.10, 1.0))
	Utility.update_world_health_bar(health_bar, hp, max_hp)
	muzzle_point = Marker2D.new()
	muzzle_point.position = Vector2(34, -40)
	add_child(muzzle_point)

func get_team() -> String:
	return Constants.TEAM_ENEMY

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO, _knockback_force: float = 0.0, source_team: String = Constants.TEAM_PLAYER) -> void:
	if destroyed or source_team == Constants.TEAM_ENEMY:
		return
	hp -= amount
	Utility.update_world_health_bar(health_bar, hp, max_hp)
	facing_direction = -1 if source_position.x < global_position.x else 1
	if hp <= 0:
		die()
	else:
		sprite.region_rect = Rect2(250, 184, 94, 82)
		EffectSpawner.spawn_effect("impact", global_position + Vector2(0, -30), facing_direction)
		AudioManager.play_sfx("metal_hit")

func die() -> void:
	destroyed = true
	collision_layer = 0
	collision_mask = 0
	if health_bar != null:
		health_bar.visible = false
	if sprite != null:
		sprite.queue_free()
		sprite = null
	_spawn_destroyed_debris()
	EffectSpawner.spawn_effect("explosion_small", global_position + Vector2(0, -24), facing_direction)
	AudioManager.play_sfx("explosion")
	GameManager.add_score(150)
	died.emit(self)

func _spawn_destroyed_debris() -> void:
	var wreck := Sprite2D.new()
	wreck.texture = WRECK_TEXTURE
	wreck.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wreck.scale = Vector2(0.22, 0.22)
	wreck.position = Vector2(0, -34)
	wreck.z_index = 10
	add_child(wreck)

func _physics_process(delta: float) -> void:
	if destroyed:
		return
	var player: Node2D = _find_player()
	if player == null:
		return
	var to_player: Vector2 = player.global_position - global_position
	if abs(to_player.x) > detection_range or abs(to_player.y) > 130.0:
		return
	facing_direction = Utility.direction_from_delta(to_player.x)
	sprite.flip_h = facing_direction < 0
	muzzle_point.position.x = 34 * facing_direction
	if pause_timer > 0.0:
		pause_timer -= delta
		return
	fire_timer -= delta
	if fire_timer <= 0.0:
		_fire()
		fire_timer = fire_rate
		burst_count += 1
		if burst_count >= burst_size:
			burst_count = 0
			pause_timer = burst_pause

func _fire() -> void:
	var bullet := BULLET_SCENE.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = muzzle_point.global_position
	bullet.setup(Vector2(facing_direction, 0), 5, Constants.TEAM_ENEMY, 430.0)
	EffectSpawner.spawn_effect("muzzle", muzzle_point.global_position, facing_direction)
	AudioManager.play_sfx("shoot_rifle")

func _find_player() -> Node2D:
	for node in get_tree().get_nodes_in_group("player"):
		if node is Node2D and is_instance_valid(node):
			return node
	return null
