extends Node

var level_started_at := 0.0

func reset_timer() -> void:
	level_started_at = Time.get_ticks_msec() / 1000.0
	GameManager.elapsed_time = 0.0

func update_timer() -> void:
	GameManager.elapsed_time = (Time.get_ticks_msec() / 1000.0) - level_started_at

func restart_timer_from(seconds: float) -> void:
	level_started_at = (Time.get_ticks_msec() / 1000.0) - seconds
	GameManager.elapsed_time = seconds

