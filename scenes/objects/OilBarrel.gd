extends StaticBody2D

const BARREL_TEXTURE = preload("res://assets/generated/oil_barrel_alpha.png")
const BARREL_DAMAGED_TEXTURE = preload("res://assets/generated/oil_barrel_damaged_alpha.png")

@export var max_hp := 35
@export var explosion_radius := 118.0
@export var explosion_damage := 45

var hp := 35
var exploded := false
var sprite: Sprite2D

func _ready() -> void:
	hp = max_hp
	add_to_group("damageables")
	add_to_group("hazards")
	collision_layer = Constants.LAYER_HAZARD
	collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY | Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_ENEMY_PROJECTILE
	Utility.make_rect_collision(self, Vector2(34, 48), Vector2(0, -24))
	sprite = Sprite2D.new()
	sprite.texture = BARREL_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -34)
	sprite.scale = Vector2(0.72, 0.72)
	add_child(sprite)

func get_team() -> String:
	return Constants.TEAM_ENVIRONMENT

func take_damage(amount: int, _source_position: Vector2 = Vector2.ZERO, _knockback_force: float = 0.0, _source_team: String = Constants.TEAM_PLAYER) -> void:
	if exploded:
		return
	hp -= amount
	if hp <= 0:
		explode()
	else:
		sprite.texture = BARREL_DAMAGED_TEXTURE

func explode() -> void:
	if exploded:
		return
	exploded = true
	collision_layer = 0
	collision_mask = 0
	EffectSpawner.spawn_effect("explosion_medium", global_position + Vector2(0, -24))
	EffectSpawner.spawn_effect("smoke", global_position + Vector2(0, -44))
	AudioManager.play_sfx("explosion")
	Utility.damage_nodes_in_radius(get_tree(), global_position, explosion_radius, explosion_damage, Constants.TEAM_ENVIRONMENT)
	GameManager.add_score(50)
	queue_free()
