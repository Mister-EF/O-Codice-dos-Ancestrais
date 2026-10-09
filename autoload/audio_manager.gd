## Null-safe music playback helper with crossfading on the Music bus.
extends Node

@export var placeholder_map_ambience: AudioStream

var _players: Array[AudioStreamPlayer] = []
var _active_index: int = 0


func _ready() -> void:
	for index: int in range(2):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
		add_child(player)
		_players.append(player)


func play_map_ambience() -> void:
	if placeholder_map_ambience == null:
		var catalog: AssetCatalog = load("res://data/asset_catalog.tres") as AssetCatalog
		if catalog != null:
			placeholder_map_ambience = catalog.music_map_ambience if catalog.music_map_ambience != null else catalog.music_world_map
	play_music(placeholder_map_ambience)


func play_music(stream: AudioStream, fade_seconds: float = 0.7) -> void:
	if stream == null or _players.size() != 2:
		return
	var next_index: int = 1 - _active_index
	var incoming: AudioStreamPlayer = _players[next_index]
	var outgoing: AudioStreamPlayer = _players[_active_index]
	incoming.stop()
	incoming.stream = stream
	incoming.volume_db = -60.0
	incoming.play()
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(incoming, "volume_db", 0.0, fade_seconds)
	if outgoing.playing:
		tween.tween_property(outgoing, "volume_db", -60.0, fade_seconds)
		tween.chain().tween_callback(outgoing.stop)
	_active_index = next_index


func stop_music(fade_seconds: float = 0.5) -> void:
	for player: AudioStreamPlayer in _players:
		if player.playing:
			var tween: Tween = create_tween()
			tween.tween_property(player, "volume_db", -60.0, fade_seconds)
			tween.tween_callback(player.stop)
