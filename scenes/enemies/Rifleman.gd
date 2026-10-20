extends EnemyBase

func _setup_stats() -> void:
	max_hp = 45
	speed = 52.0
	patrol_distance = 150.0
	detection_range = 360.0
	attack_range = 285.0
	damage = 6
	attack_cooldown = 0.8

func attack_target(_player: Node2D) -> void:
	_fire_bullet(muzzle_point.global_position, Vector2(facing_direction, 0), damage, 420.0, 2.0)

func _base_y() -> int:
	return 34
