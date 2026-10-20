extends Node

var main: Node

func _ready() -> void:
	call_deferred("_capture")

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _save(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png("res://docs/images/" + filename)
	assert(result == OK)
	print("CAPTURED: ", filename)

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/images")
	main = load("res://scenes/main/Main.tscn").instantiate()
	add_child(main)
	await _wait(0.5)
	await _save("menu.png")
	main.start_game()
	await _wait(1.0)
	var level: Node = main.current_scene
	level.player.invincible = true
	level.player.global_position = Vector2(720, 270)
	level.player._select_weapon("assault_rifle")
	await _wait(4.4)
	Input.warp_mouse(Vector2(940, 440))
	await _wait(0.3)
	await _save("forest-frontline.png")
	level.player.global_position = Vector2(5750, 270)
	level.player.unlock_weapon("rpg", 5)
	level.player.invincible = true
	await _wait(1.2)
	Input.warp_mouse(Vector2(1060, 340))
	await _wait(0.2)
	await _save("mech-showdown.png")
	main.current_level_index = 1
	main._start_level(1)
	await _wait(0.5)
	level = main.current_scene
	level.player.invincible = true
	level.player.global_position = Vector2(2490, 640)
	level.player.unlock_weapon("shotgun", 20)
	await _wait(4.8)
	Input.warp_mouse(Vector2(1000, 430))
	await _wait(0.3)
	await _save("armored-fortress.png")
	main.show_main_menu()
	await _wait(0.2)
	main.queue_free()
	await _wait(0.2)
	get_tree().quit()
