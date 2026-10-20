extends Node

func spawn_effect(effect_name: String, world_position: Vector2, direction: int = 1) -> Node2D:
	var root := get_tree().current_scene
	if root == null:
		return null
	var effect := Node2D.new()
	effect.global_position = world_position
	effect.z_index = 80
	root.add_child(effect)

	match effect_name:
		"muzzle":
			_spawn_flash(effect, Color(1.0, 0.72, 0.12, 1.0), direction)
		"impact":
			_spawn_particles(effect, Color(1.0, 0.72, 0.18, 1.0), 10, 0.18, 50.0)
		"explosion_small":
			_spawn_particles(effect, Color(1.0, 0.32, 0.05, 1.0), 28, 0.38, 115.0)
		"explosion_medium":
			_spawn_particles(effect, Color(1.0, 0.36, 0.04, 1.0), 46, 0.55, 150.0)
		"smoke":
			_spawn_particles(effect, Color(0.36, 0.35, 0.30, 0.7), 22, 0.9, 70.0)
		"pickup":
			_spawn_particles(effect, Color(1.0, 0.86, 0.18, 0.9), 16, 0.35, 52.0)
		"blood":
			_spawn_particles(effect, Color(0.75, 0.05, 0.03, 0.9), 12, 0.25, 75.0)
		_:
			_spawn_particles(effect, Color(0.9, 0.9, 0.75, 0.8), 8, 0.2, 45.0)

	get_tree().create_timer(1.2).timeout.connect(Callable(effect, "queue_free"))
	return effect

func _spawn_flash(parent: Node2D, _color: Color, _direction: int) -> void:
	parent.queue_free()

func _spawn_particles(parent: Node2D, color: Color, amount: int, lifetime: float, speed: float) -> void:
	var particles := CPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = speed * 0.3
	particles.initial_velocity_max = speed
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.8
	particles.color = color
	parent.add_child(particles)
