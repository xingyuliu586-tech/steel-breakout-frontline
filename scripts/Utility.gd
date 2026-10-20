class_name Utility
extends RefCounted

static func configure_input_actions() -> void:
	_ensure_action("move_left", [_key(KEY_A), _key(KEY_LEFT)])
	_ensure_action("move_right", [_key(KEY_D), _key(KEY_RIGHT)])
	_ensure_action("jump", [_key(KEY_W), _key(KEY_SPACE), _key(KEY_UP)])
	_ensure_action("crouch", [_key(KEY_S), _key(KEY_DOWN)])
	_ensure_action("shoot", [_mouse(MOUSE_BUTTON_LEFT), _key(KEY_J)])
	_ensure_action("reload", [_key(KEY_R)])
	_ensure_action("throw_grenade", [_key(KEY_G), _key(KEY_K)])
	_ensure_action("switch_weapon_1", [_key(KEY_1)])
	_ensure_action("switch_weapon_2", [_key(KEY_2)])
	_ensure_action("switch_weapon_3", [_key(KEY_3)])
	_ensure_action("switch_weapon_4", [_key(KEY_4)])
	_ensure_action("switch_weapon_5", [_key(KEY_5)])
	_ensure_action("switch_weapon_6", [_key(KEY_6)])
	_ensure_action("interact", [_key(KEY_E)])
	_ensure_action("pause", [_key(KEY_ESCAPE)])

static func set_pixel_defaults(node: CanvasItem) -> void:
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func make_rect_collision(parent: Node, size: Vector2, offset: Vector2 = Vector2.ZERO) -> CollisionShape2D:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = offset
	parent.add_child(collision)
	return collision

static func make_circle_collision(parent: Node, radius: float, offset: Vector2 = Vector2.ZERO) -> CollisionShape2D:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = offset
	parent.add_child(collision)
	return collision

static func make_box_visual(parent: Node, size: Vector2, color: Color, offset: Vector2 = Vector2.ZERO) -> Polygon2D:
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.5, size.y * 0.5)
	])
	visual.color = color
	visual.position = offset
	parent.add_child(visual)
	return visual

static func make_world_health_bar(parent: Node, size: Vector2, offset: Vector2, fill_color: Color = Color(0.9, 0.12, 0.08, 1.0)) -> Node2D:
	var bar := Node2D.new()
	bar.position = offset
	bar.z_index = 95
	bar.set_meta("bar_size", size)
	parent.add_child(bar)
	var border := make_box_visual(bar, size + Vector2(2, 2), Color(0.02, 0.02, 0.015, 0.92))
	border.z_index = 0
	var bg := make_box_visual(bar, size, Color(0.08, 0.08, 0.05, 0.92))
	bg.z_index = 1
	var fill := Polygon2D.new()
	fill.name = "Fill"
	fill.color = fill_color
	fill.z_index = 2
	bar.add_child(fill)
	update_world_health_bar(bar, 1, 1)
	return bar

static func update_world_health_bar(bar: Node2D, current_value: int, max_value: int) -> void:
	if bar == null:
		return
	var size := bar.get_meta("bar_size", Vector2(34, 4)) as Vector2
	var ratio: float = clampf(float(maxi(0, current_value)) / float(maxi(1, max_value)), 0.0, 1.0)
	var width := maxf(0.0, size.x * ratio)
	var left := -size.x * 0.5
	var top := -size.y * 0.5
	var fill := bar.get_node_or_null("Fill")
	if fill is Polygon2D:
		fill.polygon = PackedVector2Array([
			Vector2(left, top),
			Vector2(left + width, top),
			Vector2(left + width, top + size.y),
			Vector2(left, top + size.y)
		])

static func make_sprite(parent: Node, texture: Texture2D, region: Rect2, offset: Vector2 = Vector2.ZERO, scale_value: Vector2 = Vector2.ONE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.position = offset
	sprite.scale = scale_value
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sprite)
	return sprite

static func style_panel(panel: PanelContainer, bg: Color = Color(0.07, 0.08, 0.06, 0.92), border: Color = Color(0.38, 0.39, 0.25, 1.0)) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	panel.add_theme_stylebox_override("panel", style)

static func style_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.13, 0.09, 0.96)
	normal.border_color = Color(0.44, 0.45, 0.28, 1.0)
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = 2
	normal.corner_radius_top_right = 2
	normal.corner_radius_bottom_left = 2
	normal.corner_radius_bottom_right = 2
	var hover := normal.duplicate()
	hover.bg_color = Color(0.20, 0.22, 0.12, 1.0)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.32, 0.31, 0.11, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.95, 0.95, 0.88, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.86, 0.18, 1.0))

static func format_time(seconds: float) -> String:
	var total: int = int(seconds)
	var mins: int = floori(float(total) / 60.0)
	var secs: int = total % 60
	return "%02d:%02d" % [mins, secs]

static func direction_from_delta(delta: float) -> int:
	if delta < 0.0:
		return -1
	return 1

static func damage_nodes_in_radius(tree: SceneTree, center: Vector2, radius: float, amount: int, source_team: String = Constants.TEAM_ENVIRONMENT) -> void:
	for node in tree.get_nodes_in_group("damageables"):
		if not is_instance_valid(node):
			continue
		if not node is Node2D:
			continue
		if node.global_position.distance_to(center) > radius:
			continue
		if node.has_method("take_damage"):
			node.take_damage(amount, center, 120.0, source_team)

static func _ensure_action(action_name: StringName, events: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.5)
	if not InputMap.action_get_events(action_name).is_empty():
		return
	for event in events:
		InputMap.action_add_event(action_name, event)

static func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	return event

static func _mouse(button_index: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	return event
