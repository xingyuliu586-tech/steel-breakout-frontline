extends Node

const MAIN_MENU_SCENE = preload("res://scenes/menus/MainMenu.tscn")
const PAUSE_MENU_SCENE = preload("res://scenes/menus/PauseMenu.tscn")
const LEVEL_COMPLETE_SCENE = preload("res://scenes/menus/LevelComplete.tscn")
const GAME_OVER_SCENE = preload("res://scenes/menus/GameOver.tscn")
const LEVEL_01_SCENE = preload("res://scenes/levels/Level_01_ForestFrontline.tscn")
const LEVEL_02_SCENE = preload("res://scenes/levels/Level_02_ArmoredFortress.tscn")

var current_scene: Node
var overlay_scene: Node
var current_level_index := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Utility.configure_input_actions()
	SaveManager.load_game()
	show_main_menu()

func show_main_menu() -> void:
	GameManager.set_paused(false)
	AudioManager.stop_music()
	_clear_overlay()
	_set_current(MAIN_MENU_SCENE.instantiate())
	current_scene.start_game.connect(start_game)
	current_scene.continue_game.connect(continue_game)
	current_scene.quit_requested.connect(func() -> void: get_tree().quit())

func start_game() -> void:
	current_level_index = 0
	_start_level(current_level_index)

func continue_game() -> void:
	current_level_index = 1 if bool(SaveManager.data.get("level_01_completed", false)) else 0
	_start_level(current_level_index)

func _start_level(level_index: int) -> void:
	GameManager.set_paused(false)
	_clear_overlay()
	var level: Node = LEVEL_02_SCENE.instantiate() if level_index == 1 else LEVEL_01_SCENE.instantiate()
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	_set_current(level)
	level.pause_requested.connect(_show_pause)
	level.level_completed.connect(_show_level_complete)
	level.player_defeated.connect(_show_game_over)

func restart_level() -> void:
	_start_level(current_level_index)

func _continue_after_level_complete() -> void:
	if current_level_index == 0:
		current_level_index = 1
		_start_level(current_level_index)
	else:
		show_main_menu()

func _show_pause() -> void:
	if overlay_scene != null:
		return
	GameManager.set_paused(true)
	overlay_scene = PAUSE_MENU_SCENE.instantiate()
	add_child(overlay_scene)
	overlay_scene.resume_requested.connect(func() -> void:
		_clear_overlay()
		GameManager.set_paused(false)
	)
	overlay_scene.restart_requested.connect(restart_level)
	overlay_scene.main_menu_requested.connect(show_main_menu)

func _show_level_complete(stats: Dictionary) -> void:
	GameManager.set_paused(true)
	_clear_overlay()
	overlay_scene = LEVEL_COMPLETE_SCENE.instantiate()
	add_child(overlay_scene)
	overlay_scene.set_stats(stats)
	overlay_scene.continue_requested.connect(_continue_after_level_complete)
	overlay_scene.main_menu_requested.connect(show_main_menu)

func _show_game_over() -> void:
	GameManager.set_paused(true)
	_clear_overlay()
	overlay_scene = GAME_OVER_SCENE.instantiate()
	add_child(overlay_scene)
	overlay_scene.restart_requested.connect(restart_level)
	overlay_scene.main_menu_requested.connect(show_main_menu)

func _set_current(node: Node) -> void:
	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
	current_scene = node
	add_child(current_scene)

func _clear_overlay() -> void:
	if overlay_scene != null and is_instance_valid(overlay_scene):
		overlay_scene.queue_free()
	overlay_scene = null
