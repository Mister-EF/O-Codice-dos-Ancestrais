## GameManager — Central game state controller.
## Manages faction selection, puzzle progress, territory unlocks, settings,
## and orchestrates save/load through SaveSystem. Registered as autoload.
extends Node


## Faction enum matching the three playable factions plus NONE.
enum Faction { NONE, PIRATES, SCHOLARS, MERCENARIES }

## Map from Faction enum to the StringName id used in data files and saves.
const _FACTION_TO_ID: Dictionary = {
	Faction.NONE: &"",
	Faction.PIRATES: &"pirates",
	Faction.SCHOLARS: &"scholars",
	Faction.MERCENARIES: &"mercenaries",
}

## Reverse lookup: StringName id → Faction enum.
const _ID_TO_FACTION: Dictionary = {
	&"": Faction.NONE,
	&"pirates": Faction.PIRATES,
	&"scholars": Faction.SCHOLARS,
	&"mercenaries": Faction.MERCENARIES,
}

## Default first territory that is always unlocked.
const _DEFAULT_TERRITORY: StringName = &"territory_01"

## Loaded FactionData resources keyed by StringName id.
var _faction_data_map: Dictionary = {}

## Currently selected faction.
var _current_faction: Faction = Faction.NONE

## Best puzzle results keyed by puzzle_id.
var _puzzle_results: Dictionary = {}

## Set of unlocked territory ids.
var _unlocked_territories: Dictionary = {}

## Settings.
var _music_volume: float = 1.0
var _sfx_volume: float = 1.0
var _haptics_enabled: bool = true

## Audio bus indices (cached).
var _bus_music: int = -1
var _bus_sfx: int = -1
var _bus_ui: int = -1


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_cache_audio_buses()
	_load_faction_data()
	# Load state if a save exists.
	if SaveSystem.exists():
		load_game()
	else:
		_unlocked_territories[_DEFAULT_TERRITORY] = true


# ── Faction API ──────────────────────────────────────────────────────────────

## Select the player's faction. Persists the choice and emits faction_selected.
func select_faction(faction: Faction) -> void:
	_current_faction = faction
	var faction_id: StringName = _FACTION_TO_ID.get(faction, &"") as StringName
	EventBus.faction_selected.emit(faction_id)
	_auto_save()


## Returns the currently selected faction enum value.
func get_faction() -> Faction:
	return _current_faction


## Returns the FactionData resource for the current faction, or null if NONE.
func get_faction_data() -> FactionData:
	var faction_id: StringName = _FACTION_TO_ID.get(_current_faction, &"") as StringName
	if faction_id == &"" or not _faction_data_map.has(faction_id):
		return null
	return _faction_data_map[faction_id] as FactionData


## Returns the FactionData for a specific faction enum.
func get_faction_data_for(faction: Faction) -> FactionData:
	var faction_id: StringName = _FACTION_TO_ID.get(faction, &"") as StringName
	if faction_id == &"" or not _faction_data_map.has(faction_id):
		return null
	return _faction_data_map[faction_id] as FactionData


## Returns true if a faction has been chosen (not NONE).
func has_chosen_faction() -> bool:
	return _current_faction != Faction.NONE


# ── Puzzle Progress API ─────────────────────────────────────────────────────

## Register the result of a puzzle attempt. Keeps the best star rating per puzzle.
func register_puzzle_result(result: PuzzleResult) -> void:
	assert(result != null, "GameManager: PuzzleResult must not be null.")
	assert(result.puzzle_id != "", "GameManager: PuzzleResult.puzzle_id must not be empty.")

	var pid: String = result.puzzle_id
	if _puzzle_results.has(pid):
		var existing: Dictionary = _puzzle_results[pid] as Dictionary
		var old_stars: int = existing.get("stars", 0) as int
		if result.stars > old_stars:
			existing["stars"] = result.stars
		var old_moves: int = existing.get("best_moves", 999999) as int
		if result.moves < old_moves:
			existing["best_moves"] = result.moves
		var old_time: float = existing.get("best_time", 999999.0) as float
		if result.time_seconds < old_time:
			existing["best_time"] = result.time_seconds
	else:
		_puzzle_results[pid] = {
			"stars": result.stars,
			"best_moves": result.moves,
			"best_time": result.time_seconds,
		}

	EventBus.puzzle_completed.emit(pid, result)
	EventBus.progress_changed.emit()
	_auto_save()


## Returns the best star count for a puzzle (0 if never attempted).
func get_best_stars(puzzle_id: String) -> int:
	if _puzzle_results.has(puzzle_id):
		var data: Dictionary = _puzzle_results[puzzle_id] as Dictionary
		return data.get("stars", 0) as int
	return 0


## Returns true if the puzzle has been completed at least once.
func is_puzzle_completed(puzzle_id: String) -> bool:
	return _puzzle_results.has(puzzle_id) and get_best_stars(puzzle_id) > 0


## Returns the sum of best stars across all completed puzzles.
func get_total_stars() -> int:
	var total: int = 0
	for pid: Variant in _puzzle_results.keys():
		var data: Dictionary = _puzzle_results[pid] as Dictionary
		total += data.get("stars", 0) as int
	return total


# ── Territory API ────────────────────────────────────────────────────────────

## Unlock a territory by id. Emits territory_unlocked and progress_changed.
func unlock_territory(id: StringName) -> void:
	if not _unlocked_territories.has(id):
		_unlocked_territories[id] = true
		EventBus.territory_unlocked.emit(id)
		EventBus.progress_changed.emit()
		_auto_save()


## Returns true if the territory is unlocked.
func is_territory_unlocked(id: StringName) -> bool:
	return _unlocked_territories.has(id)


# ── Save / Load API ─────────────────────────────────────────────────────────

## Start a new game — resets all progress.
func new_game() -> void:
	_current_faction = Faction.NONE
	_puzzle_results = {}
	_unlocked_territories = {}
	_unlocked_territories[_DEFAULT_TERRITORY] = true
	SaveSystem.delete_save()
	EventBus.progress_changed.emit()


## Continue from saved state.
func continue_game() -> void:
	load_game()


## Returns true if a save file exists.
func has_save() -> bool:
	return SaveSystem.exists()


## Persist the current state to disk.
func save() -> void:
	var data: Dictionary = _build_save_data()
	SaveSystem.save(data)


## Load state from disk.
func load_game() -> void:
	var data: Dictionary = SaveSystem.load_data()
	_apply_save_data(data)


# ── Settings API ─────────────────────────────────────────────────────────────

## Get the music volume (0.0 to 1.0).
func get_music_volume() -> float:
	return _music_volume


## Set the music volume and apply to the Music audio bus.
func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	_apply_bus_volume(_bus_music, _music_volume)
	EventBus.settings_changed.emit()
	_auto_save()


## Get the SFX volume (0.0 to 1.0).
func get_sfx_volume() -> float:
	return _sfx_volume


## Set the SFX volume and apply to SFX + UI audio buses.
func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)
	_apply_bus_volume(_bus_sfx, _sfx_volume)
	_apply_bus_volume(_bus_ui, _sfx_volume)
	EventBus.settings_changed.emit()
	_auto_save()


## Returns whether haptic feedback is enabled.
func is_haptics_enabled() -> bool:
	return _haptics_enabled


## Enable or disable haptic feedback.
func set_haptics_enabled(enabled: bool) -> void:
	_haptics_enabled = enabled
	EventBus.settings_changed.emit()
	_auto_save()


# ── Internal ─────────────────────────────────────────────────────────────────

func _load_faction_data() -> void:
	var faction_dir: String = "res://data/factions/"
	var dir: DirAccess = DirAccess.open(faction_dir)
	if dir == null:
		push_error("GameManager: cannot open faction data directory '%s'." % faction_dir)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path: String = faction_dir + file_name
			var res: Resource = load(path)
			if res is FactionData:
				var fd: FactionData = res as FactionData
				_faction_data_map[fd.id] = fd
		file_name = dir.get_next()
	dir.list_dir_end()


func _cache_audio_buses() -> void:
	_bus_music = AudioServer.get_bus_index("Music")
	_bus_sfx = AudioServer.get_bus_index("SFX")
	_bus_ui = AudioServer.get_bus_index("UI")


func _apply_bus_volume(bus_idx: int, linear_volume: float) -> void:
	if bus_idx < 0:
		return
	if linear_volume <= 0.0:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_volume))


func _build_save_data() -> Dictionary:
	var territories_arr: Array = []
	for tid: Variant in _unlocked_territories.keys():
		territories_arr.append(str(tid))
	return {
		"version": SaveSystem.SAVE_VERSION,
		"locale": Localization.get_language(),
		"faction": str(_FACTION_TO_ID.get(_current_faction, &"")),
		"puzzles": _puzzle_results.duplicate(true),
		"unlocked_territories": territories_arr,
		"settings": {
			"music_volume": _music_volume,
			"sfx_volume": _sfx_volume,
			"haptics_enabled": _haptics_enabled,
		},
	}


func _apply_save_data(data: Dictionary) -> void:
	# Locale.
	var locale: String = data.get("locale", "en") as String
	if locale in Localization.SUPPORTED_LOCALES:
		Localization.set_language(locale)

	# Faction.
	var faction_str: String = data.get("faction", "") as String
	var faction_sn: StringName = StringName(faction_str)
	if _ID_TO_FACTION.has(faction_sn):
		_current_faction = _ID_TO_FACTION[faction_sn] as Faction
	else:
		_current_faction = Faction.NONE

	# Puzzles.
	var puzzles_data: Variant = data.get("puzzles", {})
	if puzzles_data is Dictionary:
		_puzzle_results = (puzzles_data as Dictionary).duplicate(true)
	else:
		_puzzle_results = {}

	# Territories.
	_unlocked_territories = {}
	_unlocked_territories[_DEFAULT_TERRITORY] = true
	var terr_arr: Variant = data.get("unlocked_territories", [])
	if terr_arr is Array:
		for tid: Variant in terr_arr as Array:
			_unlocked_territories[StringName(str(tid))] = true

	# Settings.
	var settings: Variant = data.get("settings", {})
	if settings is Dictionary:
		var s: Dictionary = settings as Dictionary
		_music_volume = float(s.get("music_volume", 1.0))
		_sfx_volume = float(s.get("sfx_volume", 1.0))
		_haptics_enabled = bool(s.get("haptics_enabled", true))
	_apply_bus_volume(_bus_music, _music_volume)
	_apply_bus_volume(_bus_sfx, _sfx_volume)
	_apply_bus_volume(_bus_ui, _sfx_volume)


func _auto_save() -> void:
	var data: Dictionary = _build_save_data()
	SaveSystem._cached_data = data.duplicate(true)
	SaveSystem.request_save()
