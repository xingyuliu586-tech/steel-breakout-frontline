extends Area2D

signal dialogue_requested(text: String, speaker: String)

const NPC_SHEET = preload("res://assets/sprites/npc/npc_characters_sheet_alpha.png")

@export var speaker_name := "指挥官"
@export var dialogue_text := "士兵，敌方通信塔正在呼叫增援。突破防线，摧毁它，然后前往撤离点。"

var player_near := false
var sprite: Sprite2D

func _ready() -> void:
	collision_layer = Constants.LAYER_INTERACTION
	collision_mask = Constants.LAYER_PLAYER
	body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			player_near = true
	)
	body_exited.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			player_near = false
	)
	Utility.make_circle_collision(self, 42.0, Vector2(0, -28))
	sprite = Utility.make_sprite(self, NPC_SHEET, Rect2(372, 44, 47, 76), Vector2(0, -34), Vector2(0.82, 0.82))

func _process(_delta: float) -> void:
	if player_near and Input.is_action_just_pressed("interact"):
		dialogue_requested.emit(dialogue_text, speaker_name)
