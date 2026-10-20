extends Area2D

signal checkpoint_reached(position: Vector2)

const CHECKPOINT_SIGN = preload("res://assets/generated/checkpoint_sign_clean_alpha.png")

var activated := false

func _ready() -> void:
	collision_layer = Constants.LAYER_INTERACTION
	collision_mask = Constants.LAYER_PLAYER
	body_entered.connect(_on_body_entered)
	Utility.make_rect_collision(self, Vector2(58, 64), Vector2(0, -32))
	var sign := Sprite2D.new()
	sign.texture = CHECKPOINT_SIGN
	sign.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sign.scale = Vector2(0.62, 0.62)
	sign.position = Vector2(0, -14)
	sign.z_index = 6
	add_child(sign)

func _on_body_entered(body: Node) -> void:
	if activated or not body.is_in_group("player"):
		return
	activated = true
	checkpoint_reached.emit(global_position)
	EffectSpawner.spawn_effect("pickup", global_position + Vector2(0, -40))
