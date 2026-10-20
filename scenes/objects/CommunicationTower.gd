extends StaticBody2D

signal destroyed

const OBJECT_SHEET = preload("res://assets/sprites/objects/defense_objectives_sheet_alpha.png")

@export var max_hp := 180

var hp := 180
var state := "intact"
var sprite: Sprite2D
var health_bar: Node2D

func _ready() -> void:
	hp = max_hp
	add_to_group("objectives")
	add_to_group("damageables")
	collision_layer = Constants.LAYER_OBJECTIVE
	collision_mask = Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_HAZARD
	Utility.make_rect_collision(self, Vector2(72, 126), Vector2(0, -64))
	sprite = Utility.make_sprite(self, OBJECT_SHEET, Rect2(326, 388, 122, 205), Vector2(0, -92), Vector2(0.74, 0.74))
	health_bar = Utility.make_world_health_bar(self, Vector2(70, 5), Vector2(0, -174), Color(0.95, 0.16, 0.10, 1.0))
	Utility.update_world_health_bar(health_bar, hp, max_hp)
	MissionManager.notify_tower_health(hp, max_hp, false)

func get_team() -> String:
	return Constants.TEAM_ENEMY

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO, _knockback_force: float = 0.0, source_team: String = Constants.TEAM_PLAYER) -> void:
	if state == "destroyed" or source_team == Constants.TEAM_ENEMY:
		return
	hp = maxi(0, hp - amount)
	Utility.update_world_health_bar(health_bar, hp, max_hp)
	EffectSpawner.spawn_effect("impact", global_position + Vector2(0, -70), Utility.direction_from_delta(global_position.x - source_position.x))
	AudioManager.play_sfx("metal_hit")
	_update_state()
	MissionManager.notify_tower_health(hp, max_hp, state != "destroyed")
	if hp <= 0:
		_destroy()

func _update_state() -> void:
	if hp <= 0:
		state = "destroyed"
		sprite.region_rect = Rect2(326, 690, 170, 120)
	elif hp <= 60:
		state = "heavily_damaged"
		sprite.region_rect = Rect2(326, 585, 126, 190)
	elif hp <= 120:
		state = "lightly_damaged"
		sprite.region_rect = Rect2(326, 492, 126, 190)
	else:
		state = "intact"
		sprite.region_rect = Rect2(326, 388, 122, 205)

func _destroy() -> void:
	collision_layer = 0
	collision_mask = 0
	if health_bar != null:
		health_bar.visible = false
	EffectSpawner.spawn_effect("explosion_medium", global_position + Vector2(0, -70))
	EffectSpawner.spawn_effect("smoke", global_position + Vector2(0, -96))
	GameManager.add_score(500)
	MissionManager.set_tower_destroyed()
	destroyed.emit()
