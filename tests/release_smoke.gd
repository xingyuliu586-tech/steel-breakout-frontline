extends Node

var failures: Array[String] = []
var main: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame
	await get_tree().process_frame

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures.append(message)
		push_error(message)

func _has_physical_key(action: StringName, key: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == key:
			return true
	return false

func _jump_to(player: CharacterBody2D, target_x: float, expected_y: float) -> void:
	Input.action_press("jump")
	Input.action_press("move_right")
	await _frames(1)
	Input.action_release("jump")
	for i in range(90):
		if player.position.x >= target_x:
			Input.action_release("move_right")
		await _frames(1)
		if i > 12 and player.is_on_floor():
			break
	Input.action_release("move_right")
	await _frames(3)
	_check(absf(player.position.y - expected_y) < 2.0,
		"ledge jump to %.0f: landed at %s (expected y %.0f)" % [target_x, player.position, expected_y])

func _run() -> void:
	main = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	await _frames(3)
	_check(main.current_scene.has_signal("start_game"), "main menu loads")
	_check(_has_physical_key("move_left", KEY_A), "A uses physical keyboard position")
	_check(_has_physical_key("move_right", KEY_D), "D uses physical keyboard position")
	_check(_has_physical_key("jump", KEY_W), "W uses physical keyboard position")
	_check(_has_physical_key("crouch", KEY_S), "S uses physical keyboard position")
	main.start_game()
	await _frames(60)
	var player: CharacterBody2D = main.current_scene.player
	_check(player.is_on_floor(), "level 1 player settles on ground")
	_check(player.weapon_system != null, "weapon system loads")
	main._show_pause()
	var paused_position := player.position
	Input.action_press("move_right")
	await _frames(20)
	Input.action_release("move_right")
	_check(player.position.is_equal_approx(paused_position), "pause stops player physics")
	main._clear_overlay()
	GameManager.set_paused(false)
	await _frames(3)

	main.current_level_index = 1
	main._start_level(1)
	await _frames(60)
	var level: Node2D = main.current_scene
	player = level.player
	player.invincible = true
	for node in get_tree().get_nodes_in_group("damageables"):
		if node != player:
			node.queue_free()
	await _frames(3)
	_check(player.is_on_floor(), "level 2 player settles on ground")
	var ledges := [Vector2(4070, 243), Vector2(4990, 223), Vector2(5870, 238)]
	for ledge in ledges:
		player.position = Vector2(ledge.x - 230, 340)
		player.velocity = Vector2.ZERO
		await _frames(5)
		await _jump_to(player, ledge.x - 130, 315)
		await _jump_to(player, ledge.x - 62, 285)
		await _jump_to(player, ledge.x - 16, 255)
		await _jump_to(player, ledge.x + 30, ledge.y)
		player.position = Vector2(ledge.x - 25, 340)
		player.velocity = Vector2.ZERO
		await _frames(4)
		Input.action_press("move_right")
		await _frames(210)
		Input.action_release("move_right")
		_check(player.position.x > ledge.x + 440, "ground route clear beneath ledge %.0f" % ledge.x)
	main.show_main_menu()
	await _frames(6)
	_check(not get_tree().paused, "return to menu clears pause")
	main.queue_free()
	await _frames(6)
	print("RELEASE_SMOKE: ", "PASS" if failures.is_empty() else "FAIL", " (", failures.size(), " failures)")
	get_tree().quit(0 if failures.is_empty() else 1)
