class_name PlayerStateMachine
extends RefCounted

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	CROUCH,
	SHOOT,
	RELOAD,
	THROW_GRENADE,
	HURT,
	DEAD
}

static func to_animation_name(state: int) -> String:
	match state:
		State.RUN:
			return "run"
		State.JUMP:
			return "jump"
		State.FALL:
			return "jump"
		State.CROUCH:
			return "crouch"
		State.SHOOT:
			return "shoot"
		State.RELOAD:
			return "reload"
		State.THROW_GRENADE:
			return "throw_grenade"
		State.HURT:
			return "hurt"
		State.DEAD:
			return "death"
		_:
			return "idle"
