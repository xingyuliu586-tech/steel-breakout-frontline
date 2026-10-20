extends Node

const SAVE_PATH = "user://save.json"

var data := {
	"level_01_completed": false,
	"best_score_level_01": 0,
	"level_02_completed": false,
	"best_score_level_02": 0,
	"total_coins": 0,
	"unlocked_weapons": ["pistol", "assault_rifle"],
	"settings": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.9
	}
}

func _ready() -> void:
	load_game()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open save file.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		data.merge(parsed, true)

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file.")
		return
	file.store_string(JSON.stringify(data, "\t"))

func complete_level_01(score: int, earned_coins: int) -> void:
	data["level_01_completed"] = true
	data["best_score_level_01"] = maxi(int(data.get("best_score_level_01", 0)), score)
	data["total_coins"] = int(data.get("total_coins", 0)) + earned_coins
	save_game()

func complete_level_02(score: int, earned_coins: int) -> void:
	data["level_02_completed"] = true
	data["best_score_level_02"] = maxi(int(data.get("best_score_level_02", 0)), score)
	data["total_coins"] = int(data.get("total_coins", 0)) + earned_coins
	save_game()
