extends Area2D

const ROCKET_TEXTURE = preload("res://assets/generated/rocket_projectile_alpha.png")

@export var explosion_radius := 118.0
@export var lifetime := 3.0

var velocity := Vector2.RIGHT
var damage := 78
var owner_team := Constants.TEAM_PLAYER
var alive_time := 0.0
var exploded := false
var sprite: Sprite2D

func _ready() -> void:
	add_to_group("projectiles")
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	Utility.make_rect_collision(self, Vector2(22, 7))
	sprite = Sprite2D.new()
	sprite.texture = ROCKET_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.13, 0.13)
	sprite.z_index = 24
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
		_explode()

func _on_body_entered(body: Node) -> void:
	_hit_node(body)

func _on_area_entered(area: Area2D) -> void:
	_hit_node(area)

func _hit_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.has_method("get_team") and node.get_team() == owner_team:
		return
	_explode()

func _explode() -> void:
	if exploded or not is_inside_tree():
		return
	exploded = true
	EffectSpawner.spawn_effect("explosion_medium", global_position)
	EffectSpawner.spawn_effect("smoke", global_position + Vector2(0, -8))
	AudioManager.play_sfx("explosion")
	Utility.damage_nodes_in_radius(get_tree(), global_position, explosion_radius, damage, owner_team)
	queue_free()
