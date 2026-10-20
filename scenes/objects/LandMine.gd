extends Area2D

const PROP_SHEET = preload("res://assets/sprites/objects/military_props_sheet_alpha.png")

@export var explosion_radius := 86.0
@export var explosion_damage := 38

var triggered := false
var sprite: Sprite2D

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = Constants.LAYER_HAZARD
	collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY
	body_entered.connect(_on_body_entered)
	Utility.make_circle_collision(self, 18.0)
	sprite = Utility.make_sprite(self, PROP_SHEET, Rect2(742, 378, 62, 54), Vector2(0, -8), Vector2(0.6, 0.6))

func get_team() -> String:
	return Constants.TEAM_ENVIRONMENT

func _on_body_entered(body: Node) -> void:
	if triggered:
		return
	if body.is_in_group("player") or body.is_in_group("enemies"):
		triggered = true
		sprite.modulate = Color(1.0, 0.3, 0.2, 1.0)
		get_tree().create_timer(0.25).timeout.connect(explode)

func explode() -> void:
	EffectSpawner.spawn_effect("explosion_small", global_position + Vector2(0, -12))
	AudioManager.play_sfx("explosion")
	Utility.damage_nodes_in_radius(get_tree(), global_position, explosion_radius, explosion_damage, Constants.TEAM_ENVIRONMENT)
	queue_free()
