extends Node

const MUSIC_PATHS := {
	"level_01": "res://assets/audio/music/forest_frontline_loop.wav"
}

const SFX_PATHS := {
	"shoot_pistol": "res://assets/audio/sfx/shoot_pistol.wav",
	"shoot_assault_rifle": "res://assets/audio/sfx/shoot_assault_rifle.wav",
	"shoot_rifle": "res://assets/audio/sfx/shoot_rifle.wav",
	"reload": "res://assets/audio/sfx/reload.wav",
	"grenade_throw": "res://assets/audio/sfx/grenade_throw.wav",
	"explosion": "res://assets/audio/sfx/explosion.wav",
	"pickup": "res://assets/audio/sfx/pickup.wav",
	"player_hit": "res://assets/audio/sfx/player_hit.wav",
	"enemy_hit": "res://assets/audio/sfx/enemy_hit.wav",
	"metal_hit": "res://assets/audio/sfx/metal_hit.wav",
	"enemy_die": "res://assets/audio/sfx/enemy_die.wav",
	"player_die": "res://assets/audio/sfx/player_die.wav"
}

var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var sfx_streams: Dictionary = {}
var music_streams: Dictionary = {}
var sfx_index := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -12.0
	add_child(music_player)
	music_player.finished.connect(func() -> void:
		if music_player.stream != null:
			music_player.play()
	)
	for i in range(10):
		var player := AudioStreamPlayer.new()
		player.volume_db = -4.0
		add_child(player)
		sfx_players.append(player)
	_load_streams()

func _exit_tree() -> void:
	stop_music()
	for player in sfx_players:
		player.stop()

func play_sfx(name: String) -> void:
	var resolved_name := _resolve_sfx_name(name)
	if not sfx_streams.has(resolved_name):
		return
	var stream := sfx_streams[resolved_name] as AudioStream
	if stream == null:
		return
	var player := _next_sfx_player()
	player.stop()
	player.stream = stream
	player.pitch_scale = randf_range(0.94, 1.06)
	player.play()

func play_music(name: String) -> void:
	if not music_streams.has(name):
		return
	var stream := music_streams[name] as AudioStream
	if stream == null:
		return
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	if music_player != null:
		music_player.stop()

func _load_streams() -> void:
	for key in SFX_PATHS.keys():
		var sfx_stream := load(String(SFX_PATHS[key])) as AudioStream
		if sfx_stream != null:
			sfx_streams[String(key)] = sfx_stream
	for key in MUSIC_PATHS.keys():
		var music_stream := load(String(MUSIC_PATHS[key])) as AudioStream
		if music_stream != null:
			music_streams[String(key)] = music_stream

func _next_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	sfx_index = (sfx_index + 1) % sfx_players.size()
	return sfx_players[sfx_index]

func _resolve_sfx_name(name: String) -> String:
	match name:
		"shoot_assault":
			return "shoot_assault_rifle"
		"shoot_shotgun":
			return "shoot_pistol"
		"shoot_sniper_rifle":
			return "shoot_rifle"
		"hurt":
			return "player_hit"
		_:
			return name
