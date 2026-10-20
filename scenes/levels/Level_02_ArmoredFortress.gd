extends Node2D

signal pause_requested
signal level_completed(stats: Dictionary)
signal player_defeated

const LEVEL_WIDTH := 7200.0
const LEVEL_HEIGHT := 720.0
const BACKGROUND = preload("res://assets/backgrounds/level_02_armored_fortress.png")
const TERRAIN_SHEET = preload("res://assets/tilesets/terrain_tiles_props_sheet_alpha.png")
const PROP_SHEET = preload("res://assets/sprites/objects/military_props_sheet_alpha.png")
const PLAYER_SCENE = preload("res://scenes/player/Player.tscn")
const RIFLEMAN_SCENE = preload("res://scenes/enemies/Rifleman.tscn")
const GRENADIER_SCENE = preload("res://scenes/enemies/Grenadier.tscn")
const TURRET_SCENE = preload("res://scenes/enemies/Turret.tscn")
const TANK_SCENE = preload("res://scenes/enemies/ArmoredTank.tscn")
const HELICOPTER_SCENE = preload("res://scenes/enemies/AttackHelicopter.tscn")
const CRATE_SCENE = preload("res://scenes/objects/DestructibleCrate.tscn")
const BARREL_SCENE = preload("res://scenes/objects/OilBarrel.tscn")
const CHECKPOINT_SCENE = preload("res://scenes/objects/Checkpoint.tscn")
const EXTRACTION_SCENE = preload("res://scenes/objects/ExtractionPoint.tscn")
const PICKUP_SCENE = preload("res://scenes/pickups/PickupBase.tscn")
const HUD_SCENE = preload("res://scenes/ui/HUD.tscn")
const DIALOGUE_SCENE = preload("res://scenes/ui/DialogueBox.tscn")

var player: Node2D
var hud: Node
var dialogue: Node
var projectiles: Node2D
var camera: Camera2D
var completed := false
var defeated := false
var lower_objective_complete := false
var upper_level_entered := false
var route_nodes: Array[Node] = []

func _ready() -> void:
	randomize()
	Utility.configure_input_actions()
	GameManager.current_level = Constants.SAVE_LEVEL_02
	GameManager.reset_run()
	LevelManager.reset_timer()
	MissionManager.reset()
	MissionManager.set_level_02_lower_objective()
	AudioManager.play_music("level_01")
	projectiles = Node2D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)
	_build_background()
	_build_world()
	_spawn_player()
	_spawn_ui()
	_spawn_encounters()
	GameManager.level_completed.connect(_on_game_manager_level_completed)
	GameManager.player_defeated.connect(_on_game_manager_player_defeated)
	get_tree().create_timer(0.7).timeout.connect(func() -> void:
		if dialogue != null:
			dialogue.show_message("装甲补给线通往山顶堡垒。先摧毁下层守门坦克，升降通道才会解锁。", "作战指挥", 4.4)
	)

func _process(delta: float) -> void:
	LevelManager.update_timer()
	_update_camera(delta)
	if lower_objective_complete and not upper_level_entered and player != null and player.global_position.y < 410.0:
		upper_level_entered = true
		MissionManager.set_level_02_command_objective()
		if hud != null:
			hud.show_hint("已进入上层堡垒，摧毁装甲指挥车。", 2.8)
	if Input.is_action_just_pressed("pause") and not completed and not defeated:
		pause_requested.emit()

func _build_background() -> void:
	var scale_value := Vector2(0.77, 0.77)
	var segment_width := float(BACKGROUND.get_width()) * scale_value.x
	var count := int(ceil(LEVEL_WIDTH / segment_width)) + 1
	for i in range(count):
		var background := Sprite2D.new()
		background.texture = BACKGROUND
		background.centered = false
		background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		background.scale = scale_value
		background.position = Vector2(float(i) * segment_width, 0)
		background.z_index = -140
		background.modulate = Color(0.92, 0.94, 0.88, 1.0)
		add_child(background)

func _build_world() -> void:
	_create_platform(Vector2(LEVEL_WIDTH * 0.5, 690), Vector2(LEVEL_WIDTH, 100), Color(0.14, 0.105, 0.06, 1.0), true)
	_create_platform(Vector2(5400, 365), Vector2(3600, 50), Color(0.14, 0.14, 0.11, 1.0), true)
	_create_platform(Vector2(4250, 255), Vector2(360, 24), Color(0.13, 0.13, 0.10, 1.0), true)
	_create_platform(Vector2(5200, 235), Vector2(420, 24), Color(0.13, 0.13, 0.10, 1.0), true)
	_create_platform(Vector2(6050, 250), Vector2(360, 24), Color(0.13, 0.13, 0.10, 1.0), true)
	_create_sandbags(Vector2(820, 635), 4)
	_create_sandbags(Vector2(1920, 635), 5)
	_create_sandbags(Vector2(2440, 635), 3)
	_create_ledge_access(4070.0)
	_create_ledge_access(4990.0)
	_create_ledge_access(5870.0)
	_scatter_props()

func _create_ledge_access(ledge_left: float) -> void:
	# Keep cover outside the low ceiling; each jump rises at most 32 pixels.
	_create_sandbags(Vector2(ledge_left - 172.0, 335), 4)
	for step in [Vector2(-62, 285), Vector2(-16, 255)]:
		var platform := _create_platform(Vector2(ledge_left + step.x, step.y + 6), Vector2(52, 12), Color(0.13, 0.13, 0.10, 1.0), true)
		for child in platform.get_children():
			if child is CollisionShape2D:
				child.one_way_collision = true

func _scatter_props() -> void:
	var props: Array[Dictionary] = [
		{"region": Rect2(192, 900, 136, 60), "pos": Vector2(540, 620), "scale": Vector2(0.38, 0.38)},
		{"region": Rect2(388, 888, 128, 76), "pos": Vector2(1480, 618), "scale": Vector2(0.36, 0.36)},
		{"region": Rect2(526, 888, 112, 76), "pos": Vector2(2360, 620), "scale": Vector2(0.38, 0.38)},
		{"region": Rect2(648, 884, 96, 82), "pos": Vector2(4000, 318), "scale": Vector2(0.34, 0.34)},
		{"region": Rect2(388, 888, 128, 76), "pos": Vector2(4800, 318), "scale": Vector2(0.34, 0.34)},
		{"region": Rect2(526, 888, 112, 76), "pos": Vector2(5750, 320), "scale": Vector2(0.34, 0.34)}
	]
	for item in props:
		var sprite := Utility.make_sprite(self, PROP_SHEET, item["region"] as Rect2, item["pos"] as Vector2, item["scale"] as Vector2)
		sprite.z_index = -1

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(110, 620)
	add_child(player)
	player.setup_projectile_parent(projectiles)
	_setup_camera()
	player.died.connect(func() -> void:
		if not defeated:
			GameManager.fail_level()
	)

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	camera.limit_left = 0
	camera.limit_right = int(LEVEL_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = int(LEVEL_HEIGHT)
	camera.position_smoothing_enabled = false
	add_child(camera)
	_update_camera(1.0)

func _update_camera(delta: float) -> void:
	if player == null or camera == null:
		return
	var target_x := clampf(player.global_position.x + 100.0, 320.0, LEVEL_WIDTH - 320.0)
	var target_y := clampf(player.global_position.y - 50.0, 180.0, LEVEL_HEIGHT - 180.0)
	camera.global_position = Vector2(
		round(lerpf(camera.global_position.x, target_x, clampf(delta * 7.0, 0.0, 1.0))),
		round(lerpf(camera.global_position.y, target_y, clampf(delta * 7.0, 0.0, 1.0)))
	)

func _spawn_ui() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.bind_player(player)
	dialogue = DIALOGUE_SCENE.instantiate()
	add_child(dialogue)

func _spawn_encounters() -> void:
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(620, 620))
	_spawn_enemy(GRENADIER_SCENE, Vector2(920, 620))
	_spawn_pickup("ammo", Vector2(1060, 605), 80)
	_spawn_pickup("shotgun", Vector2(1260, 602), 30)
	_spawn_crate(Vector2(1420, 634))
	_spawn_crate(Vector2(1480, 634))
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(1660, 620))
	_spawn_barrel(Vector2(1800, 628))
	_spawn_enemy(GRENADIER_SCENE, Vector2(2050, 620))
	_spawn_pickup("armor", Vector2(2200, 605), 30)
	_spawn_turret(Vector2(2420, 638))
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(2580, 620))
	var gate_tank := _spawn_tank(Vector2(2820, 640), 300, true)
	gate_tank.died.connect(_unlock_upper_route)
	_spawn_upper_encounters()

func _spawn_upper_encounters() -> void:
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(3860, 320))
	_spawn_enemy(GRENADIER_SCENE, Vector2(4100, 320))
	_spawn_turret(Vector2(4420, 338))
	_spawn_pickup("sniper_rifle", Vector2(4580, 305), 18)
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(4780, 320))
	_spawn_enemy(GRENADIER_SCENE, Vector2(5050, 320))
	_spawn_helicopter(Vector2(5350, 180))
	_spawn_pickup("rpg", Vector2(5520, 305), 6)
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(5750, 320))
	_spawn_turret(Vector2(6020, 338))
	var command_tank := _spawn_tank(Vector2(6500, 340), 430, true)
	command_tank.died.connect(_on_command_tank_destroyed)
	_spawn_extraction(Vector2(6980, 338))

func _unlock_upper_route(_tank: Node) -> void:
	if lower_objective_complete:
		return
	lower_objective_complete = true
	MissionManager.set_level_02_upper_route()
	var step_tops := [620.0, 592.0, 564.0, 536.0, 508.0, 480.0, 452.0, 424.0, 396.0, 368.0, 340.0]
	for i in range(step_tops.size()):
		var top_y: float = step_tops[i]
		var platform := _create_platform(Vector2(2860.0 + float(i) * 74.0, top_y + 9.0), Vector2(126, 18), Color(0.16, 0.15, 0.10, 1.0), true)
		route_nodes.append(platform)
	_spawn_pickup("health", Vector2(3304, 404), 45)
	if hud != null:
		hud.show_hint("守门坦克已摧毁，升降通道已解锁。向右跳上上层堡垒。", 4.0)

func _on_command_tank_destroyed(_tank: Node) -> void:
	MissionManager.set_level_02_extraction_ready()
	if hud != null:
		hud.show_hint("装甲指挥车已摧毁，前往右侧撤离点。", 3.2)

func _spawn_enemy(scene: PackedScene, position_value: Vector2) -> Node:
	var enemy := scene.instantiate()
	enemy.global_position = position_value
	add_child(enemy)
	return enemy

func _spawn_tank(position_value: Vector2, hp_value: int, rockets: bool) -> Node:
	var tank := TANK_SCENE.instantiate()
	tank.max_hp = hp_value
	tank.rocket_enabled = rockets
	tank.global_position = position_value
	add_child(tank)
	return tank

func _spawn_turret(position_value: Vector2) -> void:
	var turret := TURRET_SCENE.instantiate()
	turret.global_position = position_value
	add_child(turret)

func _spawn_helicopter(position_value: Vector2) -> void:
	var helicopter := HELICOPTER_SCENE.instantiate()
	helicopter.global_position = position_value
	add_child(helicopter)

func _spawn_crate(position_value: Vector2) -> void:
	var crate := CRATE_SCENE.instantiate()
	crate.global_position = position_value
	add_child(crate)

func _spawn_barrel(position_value: Vector2) -> void:
	var barrel := BARREL_SCENE.instantiate()
	barrel.global_position = position_value
	add_child(barrel)

func _spawn_pickup(type: String, position_value: Vector2, amount: int = 1) -> void:
	var pickup := PICKUP_SCENE.instantiate()
	pickup.pickup_type = type
	pickup.amount = amount
	pickup.global_position = position_value
	add_child(pickup)

func _spawn_extraction(position_value: Vector2) -> void:
	var extraction := EXTRACTION_SCENE.instantiate()
	extraction.global_position = position_value
	add_child(extraction)
	extraction.extraction_blocked.connect(func() -> void:
		if hud != null:
			hud.show_hint("先摧毁上层装甲指挥车", 2.2)
	)

func _create_platform(position_value: Vector2, size: Vector2, color: Color, add_tiles: bool) -> StaticBody2D:
	var platform := StaticBody2D.new()
	platform.position = position_value
	platform.collision_layer = Constants.LAYER_WORLD
	platform.collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY | Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_ENEMY_PROJECTILE
	platform.add_to_group("world")
	add_child(platform)
	Utility.make_rect_collision(platform, size)
	var visual := Utility.make_box_visual(platform, size, color)
	visual.z_index = -8
	if add_tiles:
		var tile_count := maxi(1, int(ceil(size.x / 44.0)))
		for i in range(tile_count):
			var local_x := -size.x * 0.5 + 22.0 + float(i) * 44.0
			var tile := Utility.make_sprite(platform, TERRAIN_SHEET, Rect2(28, 52, 62, 60), Vector2(local_x, -size.y * 0.5 + 21.0), Vector2(0.72, 0.72))
			tile.z_index = -3
	return platform

func _create_sandbags(position_value: Vector2, count: int) -> void:
	var bag := StaticBody2D.new()
	bag.position = position_value + Vector2(float(count - 1) * 14.0, 0)
	bag.collision_layer = Constants.LAYER_WORLD
	bag.collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY | Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_ENEMY_PROJECTILE
	bag.add_to_group("world")
	add_child(bag)
	Utility.make_rect_collision(bag, Vector2(float(count) * 34.0, 20), Vector2(0, -10))
	var region := Rect2(38, 250, 210, 62) if count <= 4 else Rect2(286, 250, 230, 62)
	var sprite := Utility.make_sprite(bag, PROP_SHEET, region, Vector2(0, -8), Vector2(0.50, 0.50))
	sprite.z_index = 4

func _on_game_manager_level_completed(stats: Dictionary) -> void:
	if completed:
		return
	completed = true
	level_completed.emit(stats)

func _on_game_manager_player_defeated() -> void:
	if defeated:
		return
	defeated = true
	player_defeated.emit()
