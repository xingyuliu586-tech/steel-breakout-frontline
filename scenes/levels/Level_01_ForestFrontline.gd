extends Node2D

signal pause_requested
signal level_completed(stats: Dictionary)
signal player_defeated

const BACKGROUND = preload("res://assets/backgrounds/forest_frontline_wide.png")
const TERRAIN_SHEET = preload("res://assets/tilesets/terrain_tiles_props_sheet_alpha.png")
const PROP_SHEET = preload("res://assets/sprites/objects/military_props_sheet_alpha.png")
const PLAYER_SCENE = preload("res://scenes/player/Player.tscn")
const RIFLEMAN_SCENE = preload("res://scenes/enemies/Rifleman.tscn")
const GRENADIER_SCENE = preload("res://scenes/enemies/Grenadier.tscn")
const TURRET_SCENE = preload("res://scenes/enemies/Turret.tscn")
const HELICOPTER_SCENE = preload("res://scenes/enemies/AttackHelicopter.tscn")
const MECH_BOSS_SCENE = preload("res://scenes/enemies/MechBoss.tscn")
const CRATE_SCENE = preload("res://scenes/objects/DestructibleCrate.tscn")
const BARREL_SCENE = preload("res://scenes/objects/OilBarrel.tscn")
const MINE_SCENE = preload("res://scenes/objects/LandMine.tscn")
const TOWER_SCENE = preload("res://scenes/objects/CommunicationTower.tscn")
const CHECKPOINT_SCENE = preload("res://scenes/objects/Checkpoint.tscn")
const EXTRACTION_SCENE = preload("res://scenes/objects/ExtractionPoint.tscn")
const PICKUP_SCENE = preload("res://scenes/pickups/PickupBase.tscn")
const HUD_SCENE = preload("res://scenes/ui/HUD.tscn")
const DIALOGUE_SCENE = preload("res://scenes/ui/DialogueBox.tscn")
const COMMANDER_SCENE = preload("res://scenes/npc/CommandingOfficer.tscn")

var player: Node2D
var hud: Node
var dialogue: Node
var projectiles: Node2D
var camera: Camera2D
var background_layers: Array = []
var completed := false
var defeated := false

func _ready() -> void:
	randomize()
	Utility.configure_input_actions()
	GameManager.current_level = Constants.SAVE_LEVEL_01
	GameManager.reset_run()
	LevelManager.reset_timer()
	MissionManager.reset()
	MissionManager.set_destroy_tower_objective()
	AudioManager.play_music("level_01")
	projectiles = Node2D.new()
	projectiles.name = "Projectiles"
	add_child(projectiles)
	_build_background()
	_build_world()
	_spawn_player()
	_spawn_ui()
	_spawn_npc()
	_spawn_encounters()
	_spawn_objective()
	GameManager.level_completed.connect(_on_game_manager_level_completed)
	GameManager.player_defeated.connect(_on_game_manager_player_defeated)

func _process(delta: float) -> void:
	LevelManager.update_timer()
	_update_camera(delta)
	_update_background_layers()
	if Input.is_action_just_pressed("pause") and not completed and not defeated:
		pause_requested.emit()

func _build_background() -> void:
	var background := Sprite2D.new()
	background.texture = BACKGROUND
	background.centered = false
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.position = Vector2(0, -250)
	background.z_index = -130
	background.modulate = Color(0.96, 0.98, 0.92, 1.0)
	add_child(background)

func _create_background_layer(texture: Texture2D, scale_value: Vector2, offset: Vector2, z: int, scroll_factor: float, tint: Color) -> void:
	var segment_width := texture.get_width() * scale_value.x
	var sprites: Array = []
	var count := int(ceil(Constants.LEVEL_WIDTH / segment_width)) + 4
	for i in range(count):
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = scale_value
		sprite.centered = false
		sprite.modulate = tint
		var base_x := (i - 1) * segment_width
		sprite.position = Vector2(base_x, offset.y)
		sprite.set_meta("base_x", base_x)
		sprite.z_index = z
		add_child(sprite)
		sprites.append(sprite)
	background_layers.append({
		"nodes": sprites,
		"factor": scroll_factor
	})

func _update_background_layers() -> void:
	if player == null:
		return
	var px := camera.global_position.x if camera != null else player.global_position.x
	for layer in background_layers:
		var factor: float = layer["factor"]
		for node in layer["nodes"]:
			if node is Sprite2D:
				node.position.x = float(node.get_meta("base_x")) + px * (1.0 - factor)

func _build_world() -> void:
	_create_platform(Vector2(Constants.LEVEL_WIDTH * 0.5, 311), Vector2(Constants.LEVEL_WIDTH, 82), Color(0.16, 0.11, 0.06, 1.0), true)
	for x in range(-16, int(Constants.LEVEL_WIDTH) + 80, 52):
		var tile := Utility.make_sprite(self, TERRAIN_SHEET, Rect2(28, 52, 62, 60), Vector2(x + 26, 296), Vector2(0.88, 0.88))
		tile.z_index = -4
	_create_sandbags(Vector2(1280, 268), 4)
	_create_sandbags(Vector2(2080, 268), 5)
	_create_sandbags(Vector2(4240, 268), 5)
	_create_sandbags(Vector2(5050, 268), 4)
	_create_sandbags(Vector2(5880, 268), 5)

func _scatter_ground_details() -> void:
	var detail_regions := [
		Rect2(796, 952, 38, 36),
		Rect2(852, 952, 34, 36),
		Rect2(910, 954, 34, 34),
		Rect2(968, 953, 33, 35),
		Rect2(1074, 966, 22, 22),
		Rect2(1128, 970, 45, 18),
		Rect2(1168, 1016, 40, 28),
		Rect2(1246, 1018, 35, 28)
	]
	for i in range(0, int(Constants.LEVEL_WIDTH), 170):
		var detail_index := int(i / 170) % detail_regions.size()
		var region: Rect2 = detail_regions[detail_index]
		var y_offset := 0 if i % 340 == 0 else 4
		var detail := Utility.make_sprite(self, TERRAIN_SHEET, region, Vector2(i + 90, 258 + y_offset), Vector2(0.72, 0.72))
		detail.z_index = -2

func _scatter_frontline_props() -> void:
	var props := [
		{"region": Rect2(192, 900, 136, 60), "pos": Vector2(620, 255), "scale": Vector2(0.42, 0.42)},
		{"region": Rect2(388, 888, 128, 76), "pos": Vector2(1550, 252), "scale": Vector2(0.38, 0.38)},
		{"region": Rect2(526, 888, 112, 76), "pos": Vector2(2860, 254), "scale": Vector2(0.40, 0.40)},
		{"region": Rect2(648, 884, 96, 82), "pos": Vector2(3630, 250), "scale": Vector2(0.38, 0.38)},
		{"region": Rect2(144, 890, 88, 78), "pos": Vector2(4700, 250), "scale": Vector2(0.34, 0.34)},
		{"region": Rect2(388, 888, 128, 76), "pos": Vector2(5480, 252), "scale": Vector2(0.36, 0.36)}
	]
	for item in props:
		var region := item["region"] as Rect2
		var position_value := item["pos"] as Vector2
		var scale_value := item["scale"] as Vector2
		var sprite := Utility.make_sprite(self, PROP_SHEET, region, position_value, scale_value)
		sprite.z_index = -1

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(92, 250)
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
	camera.limit_right = int(Constants.LEVEL_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 360
	camera.position_smoothing_enabled = false
	add_child(camera)
	_update_camera(1.0)

func _update_camera(delta: float) -> void:
	if player == null or camera == null:
		return
	var target_x := clampf(player.global_position.x + 110.0, 320.0, Constants.LEVEL_WIDTH - 320.0)
	var smoothed_x := lerpf(camera.global_position.x, target_x, clampf(delta * 7.0, 0.0, 1.0))
	camera.global_position = Vector2(round(smoothed_x), 180.0)

func _spawn_ui() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.bind_player(player)
	dialogue = DIALOGUE_SCENE.instantiate()
	add_child(dialogue)

func _spawn_npc() -> void:
	var commander := COMMANDER_SCENE.instantiate()
	commander.global_position = Vector2(178, 272)
	add_child(commander)
	commander.dialogue_requested.connect(func(text: String, speaker: String) -> void:
		dialogue.show_message(text, speaker, 3.8)
	)
	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		if dialogue != null:
			dialogue.show_message("士兵，敌方通信塔正在呼叫增援。突破防线，摧毁它，然后前往撤离点。", "指挥官", 4.2)
	)

func _spawn_encounters() -> void:
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(650, 250))
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(910, 250))
	_spawn_pickup("ammo", Vector2(1080, 236))
	_spawn_pickup("health", Vector2(1140, 236))
	_spawn_enemy(GRENADIER_SCENE, Vector2(1210, 250))
	_spawn_crate(Vector2(1320, 264))
	_spawn_crate(Vector2(1380, 264))
	_spawn_barrel(Vector2(1515, 258))
	_spawn_crate(Vector2(1650, 264))
	_spawn_enemy(GRENADIER_SCENE, Vector2(1840, 250))
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(2040, 250))
	_spawn_pickup("grenade", Vector2(2230, 238))
	_spawn_mine(Vector2(2440, 280))
	_spawn_mine(Vector2(2540, 280))
	_spawn_turret(Vector2(3000, 278))
	_spawn_checkpoint(Vector2(3350, 250))
	_spawn_enemy(GRENADIER_SCENE, Vector2(3520, 250))
	_spawn_pickup("armor", Vector2(3650, 236))
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(3820, 250))
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(4100, 250))
	_spawn_enemy(GRENADIER_SCENE, Vector2(4270, 250))
	_spawn_pickup("rpg", Vector2(4360, 236), 5)
	_spawn_barrel(Vector2(4460, 258))
	_spawn_pickup("ammo", Vector2(4560, 236))
	_spawn_enemy(GRENADIER_SCENE, Vector2(4700, 250))
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(4860, 250))
	_spawn_turret(Vector2(5020, 278))
	_spawn_pickup("health", Vector2(5180, 236))
	_spawn_pickup("armor", Vector2(5240, 236))

func _spawn_objective() -> void:
	var tower := TOWER_SCENE.instantiate()
	tower.global_position = Vector2(5600, 276)
	add_child(tower)
	tower.destroyed.connect(func() -> void:
		if hud != null:
			hud.show_hint("通信塔已摧毁，前往撤离点。", 2.5)
	)
	_spawn_turret(Vector2(5420, 278))
	_spawn_helicopter(Vector2(5550, 116))
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(5320, 250))
	_spawn_enemy(GRENADIER_SCENE, Vector2(5780, 250))
	_spawn_enemy(RIFLEMAN_SCENE, Vector2(5960, 250))
	_spawn_mech_boss(Vector2(6060, 270))
	_spawn_extraction(Vector2(6200, 268))

func _spawn_enemy(scene: PackedScene, position_value: Vector2) -> Node:
	var enemy := scene.instantiate()
	enemy.global_position = position_value
	add_child(enemy)
	return enemy

func _spawn_crate(position_value: Vector2) -> void:
	var crate := CRATE_SCENE.instantiate()
	crate.global_position = position_value
	add_child(crate)

func _spawn_barrel(position_value: Vector2) -> void:
	var barrel := BARREL_SCENE.instantiate()
	barrel.global_position = position_value
	add_child(barrel)

func _spawn_mine(position_value: Vector2) -> void:
	var mine := MINE_SCENE.instantiate()
	mine.global_position = position_value
	add_child(mine)
	var warning := Label.new()
	warning.text = "地雷"
	warning.add_theme_color_override("font_color", Color(1.0, 0.82, 0.18, 1.0))
	warning.position = position_value + Vector2(-24, -70)
	add_child(warning)

func _spawn_turret(position_value: Vector2) -> void:
	var turret := TURRET_SCENE.instantiate()
	turret.global_position = position_value
	add_child(turret)

func _spawn_helicopter(position_value: Vector2) -> void:
	var helicopter := HELICOPTER_SCENE.instantiate()
	helicopter.global_position = position_value
	add_child(helicopter)

func _spawn_mech_boss(position_value: Vector2) -> void:
	var boss := MECH_BOSS_SCENE.instantiate()
	boss.global_position = position_value
	add_child(boss)

func _spawn_checkpoint(position_value: Vector2) -> void:
	var checkpoint := CHECKPOINT_SCENE.instantiate()
	checkpoint.global_position = position_value
	add_child(checkpoint)
	checkpoint.checkpoint_reached.connect(func(_pos: Vector2) -> void:
		if hud != null:
			hud.show_hint("已到达检查点", 2.0)
	)

func _spawn_extraction(position_value: Vector2) -> void:
	var extraction := EXTRACTION_SCENE.instantiate()
	extraction.global_position = position_value
	add_child(extraction)
	extraction.extraction_blocked.connect(func() -> void:
		if hud != null:
			hud.show_hint("先摧毁通信塔", 2.2)
	)

func _spawn_pickup(type: String, position_value: Vector2, amount: int = 1) -> void:
	var pickup := PICKUP_SCENE.instantiate()
	pickup.pickup_type = type
	pickup.amount = amount
	pickup.global_position = position_value
	add_child(pickup)

func _create_platform(position_value: Vector2, size: Vector2, color: Color, floor: bool = false) -> StaticBody2D:
	var platform := StaticBody2D.new()
	platform.name = "Ground" if floor else "Platform"
	platform.position = position_value
	platform.collision_layer = Constants.LAYER_WORLD
	platform.collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY | Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_ENEMY_PROJECTILE
	platform.add_to_group("world")
	add_child(platform)
	Utility.make_rect_collision(platform, size)
	var visual := Utility.make_box_visual(platform, size, color)
	visual.z_index = -8 if floor else -2
	return platform

func _create_sandbags(position_value: Vector2, count: int) -> void:
	var bag := StaticBody2D.new()
	bag.position = position_value + Vector2((count - 1) * 14, 0)
	bag.collision_layer = Constants.LAYER_WORLD
	bag.collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_ENEMY | Constants.LAYER_PLAYER_PROJECTILE | Constants.LAYER_ENEMY_PROJECTILE
	bag.add_to_group("world")
	add_child(bag)
	Utility.make_rect_collision(bag, Vector2(count * 34, 20), Vector2(0, -10))
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
