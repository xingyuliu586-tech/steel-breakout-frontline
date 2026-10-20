extends Node

signal mission_updated(text: String)
signal tower_health_changed(current_hp: int, max_hp: int, visible: bool)

const MISSION_START = "突破敌军前线"
const MISSION_DESTROY_TOWER = "摧毁敌方通信塔"
const MISSION_EXTRACT = "前往撤离点"
const MISSION_COMPLETE = "任务完成"
const MISSION_LEVEL_02_LOWER = "摧毁下层守门坦克"
const MISSION_LEVEL_02_UPPER = "通过升降通道，攻入上层堡垒"
const MISSION_LEVEL_02_COMMAND = "摧毁上层装甲指挥车"
const MISSION_LEVEL_02_EXTRACT = "前往上层撤离点"

var communication_tower_destroyed := false
var extraction_unlocked := false
var current_mission_text := MISSION_START

func reset() -> void:
	communication_tower_destroyed = false
	extraction_unlocked = false
	current_mission_text = MISSION_START
	mission_updated.emit(current_mission_text)
	tower_health_changed.emit(0, 1, false)

func set_destroy_tower_objective() -> void:
	if communication_tower_destroyed:
		return
	current_mission_text = MISSION_DESTROY_TOWER
	mission_updated.emit(current_mission_text)

func set_tower_destroyed() -> void:
	communication_tower_destroyed = true
	extraction_unlocked = true
	current_mission_text = MISSION_EXTRACT
	mission_updated.emit(current_mission_text)
	tower_health_changed.emit(0, 1, false)

func set_complete() -> void:
	current_mission_text = MISSION_COMPLETE
	mission_updated.emit(current_mission_text)

func notify_tower_health(current_hp: int, max_hp: int, visible: bool) -> void:
	tower_health_changed.emit(current_hp, max_hp, visible)

func set_level_02_lower_objective() -> void:
	current_mission_text = MISSION_LEVEL_02_LOWER
	mission_updated.emit(current_mission_text)

func set_level_02_upper_route() -> void:
	current_mission_text = MISSION_LEVEL_02_UPPER
	mission_updated.emit(current_mission_text)

func set_level_02_command_objective() -> void:
	current_mission_text = MISSION_LEVEL_02_COMMAND
	mission_updated.emit(current_mission_text)

func set_level_02_extraction_ready() -> void:
	extraction_unlocked = true
	current_mission_text = MISSION_LEVEL_02_EXTRACT
	mission_updated.emit(current_mission_text)
