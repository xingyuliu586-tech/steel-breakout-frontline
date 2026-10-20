extends CanvasLayer

var player: Node
var health_bar: ProgressBar
var armor_bar: ProgressBar
var stamina_bar: ProgressBar
var ammo_label: Label
var grenade_label: Label
var mission_label: Label
var score_label: Label
var weapon_label: Label
var controls_label: Label
var tower_panel: PanelContainer
var tower_bar: ProgressBar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	GameManager.score_changed.connect(_on_score_changed)
	MissionManager.mission_updated.connect(_on_mission_updated)
	MissionManager.tower_health_changed.connect(_on_tower_health_changed)
	_on_score_changed(GameManager.score, GameManager.coins, GameManager.kills)
	_on_mission_updated(MissionManager.current_mission_text)

func bind_player(p_player: Node) -> void:
	player = p_player
	if player == null:
		return
	if player.has_signal("stats_changed"):
		player.stats_changed.connect(_on_player_stats_changed)
	if player.has_signal("ammo_changed"):
		player.ammo_changed.connect(_on_ammo_changed)
	if player.has_signal("weapon_changed"):
		player.weapon_changed.connect(_on_weapon_changed)
	if player.has_method("emit_current_status"):
		player.emit_current_status()

func show_hint(text: String, seconds: float = 2.2) -> void:
	mission_label.text = text
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if MissionManager.current_mission_text != "":
			mission_label.text = MissionManager.current_mission_text
	)

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var stats_panel := PanelContainer.new()
	stats_panel.position = Vector2(6, 6)
	stats_panel.custom_minimum_size = Vector2(214, 86)
	stats_panel.size = Vector2(214, 86)
	Utility.style_panel(stats_panel)
	root.add_child(stats_panel)
	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 1)
	stats_panel.add_child(stats_box)
	health_bar = _make_bar("生命", Color(0.88, 0.12, 0.10, 1.0), 100)
	armor_bar = _make_bar("护甲", Color(0.25, 0.64, 0.90, 1.0), 50)
	stamina_bar = _make_bar("体力", Color(0.94, 0.58, 0.08, 1.0), 100)
	stats_box.add_child(health_bar)
	stats_box.add_child(armor_bar)
	stats_box.add_child(stamina_bar)
	weapon_label = _make_small_label("手枪")
	ammo_label = _make_small_label("弹药 12/999")
	grenade_label = _make_small_label("手雷 2")
	stats_box.add_child(weapon_label)
	stats_box.add_child(ammo_label)
	stats_box.add_child(grenade_label)
	controls_label = _make_small_label("鼠标瞄准  1手枪  2步枪  3手雷  4火箭筒  G投掷")
	controls_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.18, 1.0))
	controls_label.text = "1手枪 2步枪 3手雷 4火箭 5霰弹 6狙击"
	controls_label.add_theme_font_size_override("font_size", 7)
	stats_box.add_child(controls_label)

	var mission_panel := PanelContainer.new()
	mission_panel.position = Vector2(438, 6)
	mission_panel.custom_minimum_size = Vector2(194, 42)
	mission_panel.size = Vector2(194, 42)
	Utility.style_panel(mission_panel)
	root.add_child(mission_panel)
	var mission_box := VBoxContainer.new()
	mission_box.add_theme_constant_override("separation", 1)
	mission_panel.add_child(mission_box)
	var mission_title := _make_small_label("任务")
	mission_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.16, 1.0))
	mission_box.add_child(mission_title)
	mission_label = _make_small_label("")
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_box.add_child(mission_label)

	var score_panel := PanelContainer.new()
	score_panel.position = Vector2(420, 328)
	score_panel.custom_minimum_size = Vector2(212, 24)
	score_panel.size = Vector2(212, 24)
	Utility.style_panel(score_panel)
	root.add_child(score_panel)
	score_label = _make_small_label("")
	score_panel.add_child(score_label)

	tower_panel = PanelContainer.new()
	tower_panel.position = Vector2(216, 6)
	tower_panel.custom_minimum_size = Vector2(166, 34)
	tower_panel.size = Vector2(166, 34)
	Utility.style_panel(tower_panel)
	root.add_child(tower_panel)
	var tower_box := VBoxContainer.new()
	tower_box.add_theme_constant_override("separation", 1)
	tower_panel.add_child(tower_box)
	var tower_title := _make_small_label("通信塔")
	tower_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tower_box.add_child(tower_title)
	tower_bar = _make_bar("", Color(0.9, 0.18, 0.12, 1.0), 180)
	tower_box.add_child(tower_bar)
	tower_panel.visible = false

func _make_bar(label_text: String, fill_color: Color, max_value: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(154, 7)
	bar.max_value = max_value
	bar.value = max_value
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.06, 0.04, 0.92)
	bg.border_color = Color(0.25, 0.26, 0.16, 1.0)
	bg.border_width_left = 1
	bg.border_width_right = 1
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	if label_text != "":
		bar.tooltip_text = label_text
	return bar

func _make_small_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.93, 0.93, 0.86, 1.0))
	label.add_theme_font_size_override("font_size", 8)
	return label

func _on_player_stats_changed(hp: int, max_hp: int, armor: int, max_armor: int, stamina: int, max_stamina: int, grenades: int) -> void:
	health_bar.max_value = max_hp
	health_bar.value = hp
	armor_bar.max_value = max_armor
	armor_bar.value = armor
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina
	grenade_label.text = "手雷 %d" % grenades

func _on_ammo_changed(ammo_in_magazine: int, reserve_ammo: int, _weapon_id: String) -> void:
	ammo_label.text = "弹药 %d/%d" % [ammo_in_magazine, reserve_ammo]

func _on_weapon_changed(_weapon_id: String, display_name: String) -> void:
	weapon_label.text = display_name

func _on_score_changed(score: int, coins: int, kills: int) -> void:
	score_label.text = "分数 %06d   金币 %d   击杀 %d" % [score, coins, kills]

func _on_mission_updated(text: String) -> void:
	if mission_label != null:
		mission_label.text = text

func _on_tower_health_changed(current_hp: int, max_hp: int, visible: bool) -> void:
	tower_panel.visible = visible
	tower_bar.max_value = max_hp
	tower_bar.value = current_hp
