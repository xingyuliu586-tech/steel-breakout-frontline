extends CharacterBody2D

const GRENADE_TEXTURE = preload("res://assets/generated/pickup_grenade_clean_alpha.png")

@export var fuse_time := 2.0
@export var explosion_radius := 96.0
@export var explosion_damage := 55

var owner_team := Constants.TEAM_PLAYER
var exploded := false
var fuse_timer: Timer
var sprite: Sprite2D

func _ready() -> void:
	add_to_group("projectiles")
	collision_layer = Constants.LAYER_PLAYER_PROJECTILE
	collision_mask = Constants.LAYER_WORLD | Constants.LAYER_ENEMY | Constants.LAYER_OBJECTIVE | Constants.LAYER_HAZARD
	Utility.make_circle_collision(self, 7.0)
	sprite = Sprite2D.new()
	sprite.texture = GRENADE_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.26, 0.26)
	sprite.z_index = 40
	add_child(sprite)
	fuse_timer = Timer.new()
	fuse_timer.one_shot = true
	add_child(fuse_timer)
	fuse_timer.timeout.connect(explode)
	fuse_timer.start(fuse_time)

func setup(direction: int, p_owner_team: String = Constants.TEAM_PLAYER) -> void:
	owner_team = p_owner_team
	velocity = Vector2(220.0 * direction, -220.0)
	if owner_team == Constants.TEAM_ENEMY:
		collision_layer = Constants.LAYER_ENEMY_PROJECTILE
		collision_mask = Constants.LAYER_WORLD | Constants.LAYER_PLAYER

func _physics_process(delta: float) -> void:
	if exploded:
		return
	velocity.y += Constants.GRAVITY * delta
	if sprite != null:
		sprite.rotation += delta * 10.0 * Utility.direction_from_delta(velocity.x)
	move_and_slide()
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 120.0 * delta)
		if abs(velocity.y) < 20.0:
			velocity.y = -80.0

func explode() -> void:
	if exploded:
		return
	exploded = true
	EffectSpawner.spawn_effect("explosion_medium", global_position)
	EffectSpawner.spawn_effect("smoke", global_position + Vector2(0, -12))
	AudioManager.play_sfx("explosion")
	Utility.damage_nodes_in_radius(get_tree(), global_position, explosion_radius, explosion_damage, owner_team)
	queue_free()
