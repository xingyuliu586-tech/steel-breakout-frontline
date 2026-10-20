extends CanvasLayer

var panel: PanelContainer
var speaker_label: Label
var body_label: Label
var hide_timer: Timer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide_timer = Timer.new()
	hide_timer.one_shot = true
	add_child(hide_timer)
	hide_timer.timeout.connect(_hide_box)
	_hide_box()

func show_message(text: String, speaker: String = "指挥官", seconds: float = 3.0) -> void:
	speaker_label.text = speaker
	body_label.text = text
	panel.visible = true
	hide_timer.start(seconds)

func _hide_box() -> void:
	if panel != null:
		panel.visible = false

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(86, 264)
	panel.custom_minimum_size = Vector2(500, 82)
	Utility.style_panel(panel, Color(0.04, 0.05, 0.035, 0.95), Color(0.42, 0.43, 0.26, 1.0))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	speaker_label = Label.new()
	speaker_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.17, 1.0))
	speaker_label.add_theme_font_size_override("font_size", 12)
	box.add_child(speaker_label)
	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.88, 1.0))
	body_label.add_theme_font_size_override("font_size", 13)
	box.add_child(body_label)
