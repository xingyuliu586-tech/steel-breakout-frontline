extends StaticBody2D

const PROP_SHEET = preload("res://assets/sprites/objects/military_props_sheet_alpha.png")
const PICKUP_SCENE = preload("res://scenes/pickups/PickupBase.tscn")

@export var max_hp := 30

var hp := 30
var destroyed := false
var sprite: Sprite2D

func _ready() -> void:
	hp = max_hp
	add_to_group("damageables")
	add_to_group("world")
	collision_layer = Constants.LAYER_WORLD
	collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY | Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_ENEMY_PROJECTILE
	Utility.make_rect_collision(self, Vector2(44, 42), Vector2(0, -21))
	sprite = Utility.make_sprite(self, PROP_SHEET, Rect2(38, 70, 92, 92), Vector2(0, -38), Vector2(0.62, 0.62))

func get_team() -> String:
	return Constants.TEAM_ENVIRONMENT

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO, _knockback_force: float = 0.0, _source_team: String = Constants.TEAM_PLAYER) -> void:
	if destroyed:
		return
	hp -= amount
	EffectSpawner.spawn_effect("impact", global_position + Vector2(0, -24), Utility.direction_from_delta(global_position.x - source_position.x))
	if hp <= 0:
		destroy()

func destroy() -> void:
	destroyed = true
	collision_layer = 0
	collision_mask = 0
	sprite.region_rect = Rect2(540, 70, 120, 92)
	EffectSpawner.spawn_effect("smoke", global_position + Vector2(0, -20))
	GameManager.add_score(25)
	_try_drop()
	call_deferred("queue_free")

func _try_drop() -> void:
	var roll := randf()
	var pickup_type := ""
	if roll < 0.22:
		pickup_type = "ammo"
	elif roll < 0.36:
		pickup_type = "health"
	elif roll < 0.48:
		pickup_type = "coin"
	if pickup_type == "":
		return
	var pickup := PICKUP_SCENE.instantiate()
	pickup.pickup_type = pickup_type
	pickup.global_position = global_position + Vector2(0, -34)
	get_parent().add_child(pickup)
