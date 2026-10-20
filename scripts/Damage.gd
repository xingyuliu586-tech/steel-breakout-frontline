class_name Damage
extends RefCounted

var amount := 0
var source_position := Vector2.ZERO
var knockback_force := 0.0
var source_team := Constants.TEAM_ENVIRONMENT

func _init(p_amount: int = 0, p_source_position: Vector2 = Vector2.ZERO, p_knockback_force: float = 0.0, p_source_team: String = Constants.TEAM_ENVIRONMENT) -> void:
	amount = p_amount
	source_position = p_source_position
	knockback_force = p_knockback_force
	source_team = p_source_team
