extends CanvasLayer

signal resume_requested
signal restart_requested
signal main_menu_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(226, 96)
	panel.custom_minimum_size = Vector2(190, 172)
	Utility.style_panel(panel)
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.18, 1.0))
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)
	_add_button(box, "继续", func() -> void: resume_requested.emit())
	_add_button(box, "重新开始", func() -> void: restart_requested.emit())
	_add_button(box, "主菜单", func() -> void: main_menu_requested.emit())

func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(160, 32)
	Utility.style_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
