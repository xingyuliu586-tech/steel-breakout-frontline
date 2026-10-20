extends Area2D

const PICKUP_AMMO = preload("res://assets/generated/pickup_ammo_clean_alpha.png")
const PICKUP_GRENADE = preload("res://assets/generated/pickup_grenade_clean_alpha.png")
const PICKUP_HEALTH = preload("res://assets/generated/pickup_health_clean_alpha.png")
const PICKUP_ARMOR = preload("res://assets/generated/pickup_armor_clean_alpha.png")
const PICKUP_COIN = preload("res://assets/generated/pickup_coin_clean_alpha.png")
const PICKUP_RPG = preload("res://assets/generated/rpg_pickup_alpha.png")
const PICKUP_SHOTGUN = preload("res://assets/generated/shotgun_pickup_alpha.png")
const PICKUP_SNIPER = preload("res://assets/generated/sniper_pickup_alpha.png")

@export var pickup_type := "health"
@export var amount := 1

var sprite: Sprite2D
var start_y := 0.0
var age := 0.0

func _ready() -> void:
	add_to_group("pickups")
	collision_layer = Constants.LAYER_PICKUP
	collision_mask = Constants.LAYER_PLAYER
	monitoring = true
	body_entered.connect(_on_body_entered)
	Utility.make_circle_collision(self, 24.0)
	sprite = Sprite2D.new()
	sprite.texture = _texture_for_type()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = _scale_for_type()
	sprite.z_index = 15
	add_child(sprite)
	start_y = position.y

func _physics_process(delta: float) -> void:
	age += delta
	position.y = start_y + sin(age * 4.0) * 3.0

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match pickup_type:
		"health":
			if body.has_method("heal"):
				body.heal(45)
		"ammo":
			if body.has_method("add_ammo"):
				body.add_ammo(60)
		"grenade":
			if body.has_method("add_grenades"):
				body.add_grenades(amount if amount > 0 else 1)
		"armor":
			if body.has_method("add_armor"):
				body.add_armor(25)
		"rpg":
			if body.has_method("unlock_weapon"):
				body.unlock_weapon("rpg", amount if amount > 0 else 5)
		"shotgun":
			if body.has_method("unlock_weapon"):
				body.unlock_weapon("shotgun", amount if amount > 0 else 24)
		"sniper_rifle":
			if body.has_method("unlock_weapon"):
				body.unlock_weapon("sniper_rifle", amount if amount > 0 else 15)
		"coin":
			GameManager.add_coins(maxi(1, amount))
	AudioManager.play_sfx("pickup")
	EffectSpawner.spawn_effect("pickup", global_position)
	queue_free()

func _texture_for_type() -> Texture2D:
	match pickup_type:
		"ammo":
			return PICKUP_AMMO
		"grenade":
			return PICKUP_GRENADE
		"armor":
			return PICKUP_ARMOR
		"coin":
			return PICKUP_COIN
		"rpg":
			return PICKUP_RPG
		"shotgun":
			return PICKUP_SHOTGUN
		"sniper_rifle":
			return PICKUP_SNIPER
		_:
			return PICKUP_HEALTH

func _scale_for_type() -> Vector2:
	if pickup_type == "rpg":
		return Vector2(0.22, 0.22)
	if pickup_type in ["shotgun", "sniper_rifle"]:
		return Vector2(0.42, 0.42)
	return Vector2(0.70, 0.70)
