extends Area2D

const ROUND_TEXTURE = preload("res://assets/generated/mech_autocannon_round_alpha.png")

var velocity := Vector2.RIGHT
var damage := 12
var owner_team := Constants.TEAM_ENEMY
var alive_time := 0.0

func _ready() -> void:
	add_to_group("projectiles")
	monitoring = true
	monitorable = true
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	Utility.make_rect_collision(self, Vector2(24, 9))
	var sprite := Sprite2D.new()
	sprite.texture = ROUND_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.09, 0.09)
	sprite.z_index = 25
	add_child(sprite)

func setup(direction: Vector2, p_damage: int, p_owner_team: String, speed: float) -> void:
	owner_team = p_owner_team
	damage = p_damage
	velocity = direction.normalized() * speed
	rotation = velocity.angle()
	collision_layer = Constants.LAYER_ENEMY_PROJECTILE
	collision_mask = Constants.LAYER_WORLD | Constants.LAYER_PLAYER

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	alive_time += delta
	if alive_time >= 2.0:
		queue_free()

func _on_hit(node: Node) -> void:
	if node.has_method("get_team") and node.get_team() == owner_team:
		return
	if node.has_method("take_damage"):
		node.take_damage(damage, global_position, 110.0, owner_team)
	EffectSpawner.spawn_effect("impact", global_position, Utility.direction_from_delta(velocity.x))
	queue_free()
