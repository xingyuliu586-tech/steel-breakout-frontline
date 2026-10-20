extends Area2D

const BULLET_TEXTURE = preload("res://assets/generated/bullet_tracer_alpha.png")

var velocity := Vector2.RIGHT
var damage := 10
var owner_team := Constants.TEAM_PLAYER
var lifetime := 1.5
var alive_time := 0.0

var sprite: Sprite2D

func _ready() -> void:
	add_to_group("projectiles")
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	Utility.make_rect_collision(self, Vector2(18, 5))
	sprite = Sprite2D.new()
	sprite.texture = BULLET_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.12, 0.12)
	sprite.z_index = 20
	add_child(sprite)

func setup(direction: Vector2, p_damage: int, p_owner_team: String, speed: float) -> void:
	owner_team = p_owner_team
	damage = p_damage
	velocity = direction.normalized() * speed
	rotation = velocity.angle()
	if owner_team == Constants.TEAM_PLAYER:
		collision_layer = Constants.LAYER_PLAYER_PROJECTILE
		collision_mask = Constants.LAYER_WORLD | Constants.LAYER_ENEMY | Constants.LAYER_OBJECTIVE | Constants.LAYER_HAZARD
	else:
		collision_layer = Constants.LAYER_ENEMY_PROJECTILE
		collision_mask = Constants.LAYER_WORLD | Constants.LAYER_PLAYER

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	alive_time += delta
	if alive_time >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_hit_node(body)

func _on_area_entered(area: Area2D) -> void:
	_hit_node(area)

func _hit_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.has_method("get_team") and node.get_team() == owner_team:
		return
	if node.has_method("take_damage"):
		node.take_damage(damage, global_position, 60.0, owner_team)
	EffectSpawner.spawn_effect("impact", global_position, Utility.direction_from_delta(velocity.x))
	queue_free()
