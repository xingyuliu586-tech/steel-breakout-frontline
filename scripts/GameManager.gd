extends Node

signal score_changed(score: int, coins: int, kills: int)
signal game_paused_changed(paused: bool)
signal level_completed(stats: Dictionary)
signal player_defeated

var score := 0
var coins := 0
var kills := 0
var elapsed_time := 0.0
var current_level := Constants.SAVE_LEVEL_01

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset_run() -> void:
	score = 0
	coins = 0
	kills = 0
	elapsed_time = 0.0
	score_changed.emit(score, coins, kills)

func add_score(amount: int) -> void:
	score = maxi(0, score + amount)
	score_changed.emit(score, coins, kills)

func add_coins(amount: int) -> void:
	coins = maxi(0, coins + amount)
	score += amount * 10
	score_changed.emit(score, coins, kills)

func add_kill() -> void:
	kills += 1
	add_score(100)

func set_paused(value: bool) -> void:
	get_tree().paused = value
	game_paused_changed.emit(value)

func complete_level() -> void:
	var stats := {
		"time": elapsed_time,
		"kills": kills,
		"score": score,
		"coins": coins
	}
	if current_level == Constants.SAVE_LEVEL_02:
		SaveManager.complete_level_02(score, coins)
	else:
		SaveManager.complete_level_01(score, coins)
	level_completed.emit(stats)

func fail_level() -> void:
	player_defeated.emit()
