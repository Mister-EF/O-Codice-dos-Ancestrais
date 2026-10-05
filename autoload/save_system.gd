## SaveSystem — Handles local JSON persistence with atomic writes,
## corruption recovery, version migration, and debounced auto-save.
## Registered as autoload.
extends Node


## Current save format version. Bump when the schema changes.
const SAVE_VERSION: int = 1

## Path to the save file.
const SAVE_PATH: String = "user://codex_save.json"

## Backup path for corrupted save files.
const BACKUP_PATH: String = "user://codex_save.json.bak"

## Temporary path used during atomic writes.
const TEMP_PATH: String = "user://codex_save.tmp.json"

## Debounce interval in seconds — rapid save requests are coalesced.
const DEBOUNCE_SECONDS: float = 1.0

## Cached save data (always kept in sync with disk).
var _cached_data: Dictionary = {}

## Whether a save is already scheduled.
var _save_pending: bool = false

## Timer node for debouncing.
var _debounce_timer: Timer


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_debounce_timer = Timer.new()
	_debounce_timer.one_shot = true
	_debounce_timer.wait_time = DEBOUNCE_SECONDS
	_debounce_timer.timeout.connect(_on_debounce_timeout)
	add_child(_debounce_timer)

	_cached_data = load_data()


# ── Public API ───────────────────────────────────────────────────────────────

## Immediately write a full data dictionary to disk. Returns true on success.
func save(data: Dictionary) -> bool:
	_cached_data = data.duplicate(true)
	_cached_data["version"] = SAVE_VERSION
	var success: bool = _write_atomic(_cached_data)
	EventBus.save_completed.emit(success)
	return success


## Load and return the saved data dictionary. Returns defaults on failure.
func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_data()

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: cannot open save file: %s" % error_string(FileAccess.get_open_error()))
		return _default_data()

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: Error = json.parse(json_text)
	if err != OK:
		push_error("SaveSystem: corrupted save (parse error line %d: %s). Backing up and resetting." % [json.get_error_line(), json.get_error_message()])
		_backup_corrupted()
		return _default_data()

	var data: Variant = json.data
	if not data is Dictionary:
		push_error("SaveSystem: save root is not a Dictionary. Backing up and resetting.")
		_backup_corrupted()
		return _default_data()

	var dict: Dictionary = data as Dictionary
	dict = _fill_defaults(dict)
	var from_version: int = dict.get("version", 0) as int
	if from_version < SAVE_VERSION:
		dict = _migrate(dict, from_version)
	return dict


## Delete the save file.
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_cached_data = _default_data()


## Returns true if a save file exists on disk.
func exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Returns the current cached save data (read-only view).
func get_cached_data() -> Dictionary:
	return _cached_data


## Schedule a debounced save using the cached data.
## Call this from other systems when data changes.
func request_save() -> void:
	_save_pending = true
	if _debounce_timer.is_stopped():
		_debounce_timer.start(DEBOUNCE_SECONDS)


## Update a single top-level key in the cached data and schedule a save.
func set_value(key: String, value: Variant) -> void:
	_cached_data[key] = value
	request_save()


## Read a single top-level key from cached data with a default.
func get_value(key: String, default: Variant = null) -> Variant:
	return _cached_data.get(key, default)


# ── Internal ─────────────────────────────────────────────────────────────────

func _on_debounce_timeout() -> void:
	if _save_pending:
		_save_pending = false
		_cached_data["version"] = SAVE_VERSION
		var success: bool = _write_atomic(_cached_data)
		EventBus.save_completed.emit(success)


func _write_atomic(data: Dictionary) -> bool:
	# Write to temp file first, then rename for atomicity.
	var json_text: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: cannot create temp file: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(json_text)
	file.close()

	# Remove old save, rename temp to real path.
	if FileAccess.file_exists(SAVE_PATH):
		var rm_err: Error = DirAccess.remove_absolute(SAVE_PATH)
		if rm_err != OK:
			push_error("SaveSystem: cannot remove old save: %s" % error_string(rm_err))
			return false

	var rename_err: Error = DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
	if rename_err != OK:
		push_error("SaveSystem: cannot rename temp to save: %s" % error_string(rename_err))
		return false

	return true


func _backup_corrupted() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		# Remove existing backup if present.
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.remove_absolute(BACKUP_PATH)
		DirAccess.rename_absolute(SAVE_PATH, BACKUP_PATH)
		push_warning("SaveSystem: corrupted save backed up to '%s'." % BACKUP_PATH)


func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"locale": "en",
		"faction": "",
		"puzzles": {},
		"unlocked_territories": ["territory_01"],
		"settings": {
			"music_volume": 1.0,
			"sfx_volume": 1.0,
			"haptics_enabled": true,
		},
	}


func _fill_defaults(data: Dictionary) -> Dictionary:
	var defaults: Dictionary = _default_data()
	for key: String in defaults.keys():
		if not data.has(key):
			data[key] = defaults[key]
	# Fill nested settings defaults.
	if data.has("settings") and data["settings"] is Dictionary:
		var s: Dictionary = data["settings"] as Dictionary
		var ds: Dictionary = defaults["settings"] as Dictionary
		for sk: String in ds.keys():
			if not s.has(sk):
				s[sk] = ds[sk]
	return data


func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	# Future migration steps go here.
	# Example:
	# if from_version < 2:
	#     data["new_field"] = "default"
	#     from_version = 2
	data["version"] = SAVE_VERSION
	return data
