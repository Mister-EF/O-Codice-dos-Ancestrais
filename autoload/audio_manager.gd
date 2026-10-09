## AudioManager — Bus-aware, null-safe audio player with music crossfade support.
class_name AudioManagerAutoload
extends Node

const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer = null
var _sfx_player: AudioStreamPlayer
var _crossfade_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_player_a = AudioStreamPlayer.new()
	_player_a.bus = MUSIC_BUS
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.bus = MUSIC_BUS
	add_child(_player_b)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = SFX_BUS
	add_child(_sfx_player)


## Plays a music stream with smooth crossfading. If stream is null, stops playing.
func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
	if stream == null:
		stop_music(fade_duration)
		return

	if _active_player != null and _active_player.playing and _active_player.stream == stream:
		return # Already playing this stream

	var next_player: AudioStreamPlayer = _player_b if _active_player == _player_a else _player_a
	var prev_player: AudioStreamPlayer = _active_player

	next_player.stream = stream
	next_player.volume_db = -80.0
	next_player.play()
	_active_player = next_player

	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	_crossfade_tween = create_tween().set_parallel(true)
	_crossfade_tween.tween_property(next_player, "volume_db", 0.0, fade_duration)
	if prev_player != null and prev_player.playing:
		_crossfade_tween.tween_property(prev_player, "volume_db", -80.0, fade_duration)
		_crossfade_tween.chain().tween_callback(prev_player.stop)


## Stops current music with a fade out.
func stop_music(fade_duration: float = 1.0) -> void:
	if _active_player == null or not _active_player.playing:
		return

	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()

	var target: AudioStreamPlayer = _active_player
	_active_player = null

	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(target, "volume_db", -80.0, fade_duration)
	_crossfade_tween.tween_callback(target.stop)


## Plays a one-shot sound effect null-safely.
func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.play()


## Returns currently playing stream or null.
func get_current_music() -> AudioStream:
	if _active_player != null and _active_player.playing:
		return _active_player.stream
	return null
