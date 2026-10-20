extends CanvasLayer

signal start_game
signal continue_game
signal quit_requested

const MENU_BACKGROUND = preload("res://assets/backgrounds/forest_frontline_background.png")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var background := TextureRect.new()
	background.texture = MENU_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.02, 0.42)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var title := Label.new()
	title.text = "钢铁突围"
	title.position = Vector2(112, 52)
	title.size = Vector2(420, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.16, 1.0))
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "前线行动"
	subtitle.position = Vector2(188, 96)
	subtitle.size = Vector2(270, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.86, 0.86, 0.76, 1.0))
	root.add_child(subtitle)

	var panel := PanelContainer.new()
	panel.position = Vector2(226, 142)
	panel.custom_minimum_size = Vector2(190, 118)
	Utility.style_panel(panel)
	root.add_child(panel)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	panel.add_child(buttons)
	_add_button(buttons, "开始游戏", func() -> void: start_game.emit())
	if bool(SaveManager.data.get("level_01_completed", false)):
		_add_button(buttons, "继续第二关", func() -> void: continue_game.emit())
	_add_button(buttons, "退出", func() -> void: quit_requested.emit())

func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(160, 32)
	Utility.style_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)

