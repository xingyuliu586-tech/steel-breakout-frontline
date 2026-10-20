extends Area2D

signal extraction_blocked

const EXTRACTION_GATE = preload("res://assets/generated/extraction_gate_alpha.png")
const RADIO_BOX = preload("res://assets/generated/radio_box_alpha.png")
const AMMO_CRATE = preload("res://assets/generated/ammo_crate_generated_alpha.png")
const SMOKE_BEACON = preload("res://assets/generated/smoke_beacon_alpha.png")

var beacon: Polygon2D
var beacon_glow: Polygon2D
var glow_time := 0.0

func _ready() -> void:
	collision_layer = Constants.LAYER_INTERACTION
	collision_mask = Constants.LAYER_PLAYER
	body_entered.connect(_on_body_entered)
	Utility.make_rect_collision(self, Vector2(172, 116), Vector2(0, -58))
	_build_extraction_gate()

func _process(delta: float) -> void:
	glow_time += delta
	var pulse := 0.45 + sin(glow_time * 5.0) * 0.25
	if beacon_glow != null:
		var glow_color := beacon_glow.modulate
		glow_color.a = pulse
		beacon_glow.modulate = glow_color

func _build_extraction_gate() -> void:
	var gate := Sprite2D.new()
	gate.texture = EXTRACTION_GATE
	gate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gate.scale = Vector2(0.21, 0.21)
	gate.position = Vector2(0, -50)
	gate.z_index = 6
	add_child(gate)
	_add_generated_prop(RADIO_BOX, Vector2(-82, -18), Vector2(0.20, 0.20), 8)
	_add_generated_prop(AMMO_CRATE, Vector2(-46, -13), Vector2(0.22, 0.22), 8)
	_add_generated_prop(SMOKE_BEACON, Vector2(88, -22), Vector2(0.20, 0.20), 7)
	var label := Label.new()
	label.text = "撤离点"
	label.position = Vector2(48, -92)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.25, 1.0))
	label.add_theme_font_size_override("font_size", 9)
	label.z_index = 9
	add_child(label)
	beacon_glow = Polygon2D.new()
	beacon_glow.color = Color(1.0, 0.82, 0.16, 0.26)
	beacon_glow.polygon = PackedVector2Array([Vector2(-10, -110), Vector2(10, -110), Vector2(56, -52), Vector2(-56, -52)])
	beacon_glow.z_index = 6
	add_child(beacon_glow)

func _add_generated_prop(texture: Texture2D, offset: Vector2, scale_value: Vector2, z: int) -> void:
	var prop := Sprite2D.new()
	prop.texture = texture
	prop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	prop.scale = scale_value
	prop.position = offset
	prop.z_index = z
	add_child(prop)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if MissionManager.extraction_unlocked:
		MissionManager.set_complete()
		GameManager.complete_level()
	else:
		extraction_blocked.emit()
