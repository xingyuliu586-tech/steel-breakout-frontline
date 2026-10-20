extends EnemyBase

func _setup_stats() -> void:
	max_hp = 55
	speed = 46.0
	patrol_distance = 170.0
	detection_range = 390.0
	attack_range = 245.0
	damage = 18
	attack_cooldown = 1.9

func _update_ai(player: Node2D, delta: float) -> void:
	var to_player: Vector2 = player.global_position - global_position
	var horizontal_distance: float = abs(to_player.x)
	var track_range := detection_range + (70.0 if state == State.CHASE or state == State.ATTACK else 0.0)
	if horizontal_distance <= track_range and abs(to_player.y) < 140.0:
		facing_direction = Utility.direction_from_delta(to_player.x)
		if horizontal_distance < 130.0:
			state = State.CHASE
			velocity.x = -facing_direction * speed
		elif horizontal_distance <= attack_range:
			state = State.ATTACK
			velocity.x = move_toward(velocity.x, 0.0, speed * 4.0 * delta)
			if attack_timer <= 0.0:
				attack_timer = attack_cooldown
				attack_target(player)
		else:
			state = State.CHASE
			velocity.x = facing_direction * speed
	else:
		_patrol(delta)

func attack_target(_player: Node2D) -> void:
	_throw_grenade(global_position + Vector2(20 * facing_direction, -42), facing_direction)

func _base_y() -> int:
	return 586
