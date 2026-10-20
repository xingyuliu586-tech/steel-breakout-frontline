extends Area2D

const MISSILE_TEXTURE = preload("res://assets/generated/mech_boss_missile_alpha.png")

var velocity := Vector2.RIGHT
var damage := 44
var owner_team := Constants.TEAM_ENEMY
var alive_time := 0.0
var exploded := false

func _ready() -> void:
	add_to_group("projectiles")
	monitoring = true
	monitorable = true
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)
	Utility.make_rect_collision(self, Vector2(35, 13))
	var sprite := Sprite2D.new()
	sprite.texture = MISSILE_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.12, 0.12)
	sprite.z_index = 26
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
	if alive_time >= 3.2:
		_explode()

func _on_hit(node: Node) -> void:
	if node.has_method("get_team") and node.get_team() == owner_team:
		return
	_explode()

func _explode() -> void:
	if exploded:
		return
	exploded = true
	EffectSpawner.spawn_effect("explosion_medium", global_position)
	EffectSpawner.spawn_effect("smoke", global_position)
	AudioManager.play_sfx("explosion")
	Utility.damage_nodes_in_radius(get_tree(), global_position, 112.0, damage, owner_team)
	queue_free()
