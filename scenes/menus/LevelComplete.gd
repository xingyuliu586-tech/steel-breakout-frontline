extends CanvasLayer

signal continue_requested
signal main_menu_requested

var stats_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func set_stats(stats: Dictionary) -> void:
	if stats_label == null:
		return
	stats_label.text = "用时  %s\n击杀  %d\n分数  %06d\n金币  %d" % [
		Utility.format_time(float(stats.get("time", 0.0))),
		int(stats.get("kills", 0)),
		int(stats.get("score", 0)),
		int(stats.get("coins", 0))
	]

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(154, 72)
	panel.custom_minimum_size = Vector2(334, 230)
	Utility.style_panel(panel)
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	var title := Label.new()
	title.text = "任务完成！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.16, 1.0))
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var stars := Label.new()
	stars.text = "*  *  *"
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_color_override("font_color", Color(1.0, 0.78, 0.10, 1.0))
	stars.add_theme_font_size_override("font_size", 24)
	box.add_child(stars)
	stats_label = Label.new()
	stats_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.88, 1.0))
	stats_label.add_theme_font_size_override("font_size", 14)
	box.add_child(stats_label)
	_add_button(box, "继续", func() -> void: continue_requested.emit())
	_add_button(box, "主菜单", func() -> void: main_menu_requested.emit())

func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(288, 32)
	Utility.style_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
