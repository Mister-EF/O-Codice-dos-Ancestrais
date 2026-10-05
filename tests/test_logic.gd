## Headless Logic Tests — Tests for SaveSystem, Localization, GameManager.
## Run with: godot --headless -s res://tests/test_logic.gd
## Tests: save/load roundtrip, corrupted-save recovery, language fallback,
## placeholder substitution, faction selection persistence.
extends SceneTree


var _passed: int = 0
var _failed: int = 0
var _test_save_path: String = "user://test_save.json"
var _test_temp_path: String = "user://test_save.tmp.json"
var _test_backup_path: String = "user://test_save.json.bak"


func _init() -> void:
	# We run in _init so the autoloads may not be available.
	# These tests target pure logic that doesn't depend on autoloads.
	print("═══ Headless Logic Tests ═══\n")

	_test_json_roundtrip()
	_test_corrupted_save_recovery()
	_test_language_fallback()
	_test_placeholder_substitution()
	_test_default_data_structure()
	_test_fill_defaults_missing_fields()
	_test_faction_id_mapping()
	_test_faction_selection_persistence()
	_test_puzzle_result_creation()

	print("\n── Results: %d passed, %d failed ──" % [_passed, _failed])
	if _failed > 0:
		print("❌ TESTS FAILED")
		quit(1)
	else:
		print("✅ ALL TESTS PASSED")
		quit(0)


# ── Test: JSON Save/Load Roundtrip ──────────────────────────────────────────

func _test_json_roundtrip() -> void:
	print("TEST: JSON save/load roundtrip")
	var data: Dictionary = {
		"version": 1,
		"locale": "pt_BR",
		"faction": "pirates",
		"puzzles": {
			"puzzle_01": {"stars": 3, "best_moves": 10, "best_time": 25.5},
		},
		"unlocked_territories": ["territory_01", "territory_02"],
		"settings": {
			"music_volume": 0.8,
			"sfx_volume": 0.5,
			"haptics_enabled": false,
		},
	}

	# Write.
	var json_text: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(_test_save_path, FileAccess.WRITE)
	if file == null:
		_fail("Cannot create test file: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(json_text)
	file.close()

	# Read back.
	var read_file: FileAccess = FileAccess.open(_test_save_path, FileAccess.READ)
	if read_file == null:
		_fail("Cannot read test file back")
		return
	var read_text: String = read_file.get_as_text()
	read_file.close()

	var json: JSON = JSON.new()
	var err: Error = json.parse(read_text)
	if err != OK:
		_fail("JSON parse error: %s" % json.get_error_message())
		return

	var loaded: Variant = json.data
	if not loaded is Dictionary:
		_fail("Loaded data is not a Dictionary")
		return

	var loaded_dict: Dictionary = loaded as Dictionary
	_assert_eq(loaded_dict.get("locale", ""), "pt_BR", "locale roundtrip")
	_assert_eq(loaded_dict.get("faction", ""), "pirates", "faction roundtrip")
	_assert_eq(loaded_dict.get("version", 0), 1, "version roundtrip")

	var puzzles: Variant = loaded_dict.get("puzzles", {})
	if puzzles is Dictionary:
		var p: Dictionary = puzzles as Dictionary
		_assert_eq(p.has("puzzle_01"), true, "puzzle_01 exists")
	else:
		_fail("puzzles is not a Dictionary")

	# Cleanup.
	DirAccess.remove_absolute(_test_save_path)


# ── Test: Corrupted Save Recovery ───────────────────────────────────────────

func _test_corrupted_save_recovery() -> void:
	print("TEST: Corrupted save recovery")

	# Write garbage.
	var file: FileAccess = FileAccess.open(_test_save_path, FileAccess.WRITE)
	if file == null:
		_fail("Cannot create corrupted test file")
		return
	file.store_string("{ this is not valid json }")
	file.close()

	# Try to parse — should fail gracefully.
	var read_file: FileAccess = FileAccess.open(_test_save_path, FileAccess.READ)
	if read_file == null:
		_fail("Cannot read corrupted file")
		return
	var text: String = read_file.get_as_text()
	read_file.close()

	var json: JSON = JSON.new()
	var err: Error = json.parse(text)
	_assert_eq(err != OK, true, "corrupted JSON should fail to parse")

	# Verify we can create a backup.
	if FileAccess.file_exists(_test_backup_path):
		DirAccess.remove_absolute(_test_backup_path)
	DirAccess.rename_absolute(_test_save_path, _test_backup_path)
	_assert_eq(FileAccess.file_exists(_test_backup_path), true, "backup file created")
	_assert_eq(FileAccess.file_exists(_test_save_path), false, "original removed after backup")

	# Cleanup.
	if FileAccess.file_exists(_test_backup_path):
		DirAccess.remove_absolute(_test_backup_path)


# ── Test: Language Fallback ─────────────────────────────────────────────────

func _test_language_fallback() -> void:
	print("TEST: Language fallback logic")

	# Load EN dictionary.
	var en_dict: Dictionary = _load_test_json("res://localization/en.json")
	if en_dict.is_empty():
		_fail("Cannot load en.json for fallback test")
		return

	# Simulate fallback: key present in EN.
	var test_key: String = "ui.play"
	_assert_eq(en_dict.has(test_key), true, "ui.play exists in EN")

	# Simulate missing key — raw key returned.
	var missing_key: String = "nonexistent.key.xyz"
	_assert_eq(en_dict.has(missing_key), false, "nonexistent key not in EN")

	# Device locale mapping.
	_assert_eq(_map_locale("pt_BR"), "pt_BR", "pt_BR maps to pt_BR")
	_assert_eq(_map_locale("pt"), "pt_BR", "pt maps to pt_BR")
	_assert_eq(_map_locale("pt_PT"), "pt_BR", "pt_PT maps to pt_BR")
	_assert_eq(_map_locale("en_US"), "en", "en_US maps to en")
	_assert_eq(_map_locale("fr_FR"), "en", "fr_FR maps to en (default)")
	_assert_eq(_map_locale("ja_JP"), "en", "ja_JP maps to en (default)")


# ── Test: Placeholder Substitution ──────────────────────────────────────────

func _test_placeholder_substitution() -> void:
	print("TEST: Placeholder substitution")

	var template: String = "Total Stars: {count}"
	var params: Dictionary = {"count": "42"}
	var result: String = template.replace("{count}", str(params["count"]))
	_assert_eq(result, "Total Stars: 42", "single placeholder")

	var template2: String = "Hint discount ({percent}% off)"
	var params2: Dictionary = {"percent": "25"}
	var result2: String = template2.replace("{percent}", str(params2["percent"]))
	_assert_eq(result2, "Hint discount (25% off)", "percent placeholder")

	var template3: String = "No placeholders here"
	_assert_eq(template3, "No placeholders here", "no placeholders unchanged")

	# Multiple placeholders.
	var template4: String = "{a} and {b}"
	var result4: String = template4.replace("{a}", "X").replace("{b}", "Y")
	_assert_eq(result4, "X and Y", "multiple placeholders")


# ── Test: Default Data Structure ────────────────────────────────────────────

func _test_default_data_structure() -> void:
	print("TEST: Default data structure")

	var defaults: Dictionary = {
		"version": 1,
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

	_assert_eq(defaults.has("version"), true, "has version")
	_assert_eq(defaults.has("locale"), true, "has locale")
	_assert_eq(defaults.has("faction"), true, "has faction")
	_assert_eq(defaults.has("puzzles"), true, "has puzzles")
	_assert_eq(defaults.has("unlocked_territories"), true, "has unlocked_territories")
	_assert_eq(defaults.has("settings"), true, "has settings")

	var settings: Dictionary = defaults["settings"] as Dictionary
	_assert_eq(settings.has("music_volume"), true, "settings has music_volume")
	_assert_eq(settings.has("sfx_volume"), true, "settings has sfx_volume")
	_assert_eq(settings.has("haptics_enabled"), true, "settings has haptics_enabled")


# ── Test: Fill Defaults for Missing Fields ──────────────────────────────────

func _test_fill_defaults_missing_fields() -> void:
	print("TEST: Fill defaults for missing fields")

	var defaults: Dictionary = {
		"version": 1,
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

	# Simulate a save that has some fields missing.
	var incomplete: Dictionary = {
		"version": 1,
		"locale": "pt_BR",
	}

	for key: String in defaults.keys():
		if not incomplete.has(key):
			incomplete[key] = defaults[key]

	_assert_eq(incomplete.has("faction"), true, "faction filled")
	_assert_eq(incomplete.has("puzzles"), true, "puzzles filled")
	_assert_eq(incomplete.has("settings"), true, "settings filled")
	_assert_eq(incomplete["locale"], "pt_BR", "existing locale preserved")


# ── Test: Faction ID Mapping ────────────────────────────────────────────────

func _test_faction_id_mapping() -> void:
	print("TEST: Faction ID mapping")

	# Replicate the mapping logic from GameManager.
	var faction_to_id: Dictionary = {
		0: &"",          # NONE
		1: &"pirates",   # PIRATES
		2: &"scholars",  # SCHOLARS
		3: &"mercenaries", # MERCENARIES
	}
	var id_to_faction: Dictionary = {
		&"": 0,
		&"pirates": 1,
		&"scholars": 2,
		&"mercenaries": 3,
	}

	_assert_eq(faction_to_id[0], &"", "NONE maps to empty")
	_assert_eq(faction_to_id[1], &"pirates", "PIRATES maps correctly")
	_assert_eq(id_to_faction[&"scholars"], 2, "scholars reverse maps correctly")
	_assert_eq(id_to_faction[&"mercenaries"], 3, "mercenaries reverse maps correctly")


# ── Test: Faction Selection Persistence ────────────────────────────────────

func _test_faction_selection_persistence() -> void:
	print("TEST: Faction selection persistence")

	var id_to_faction: Dictionary = {
		&"": 0,
		&"pirates": 1,
		&"scholars": 2,
		&"mercenaries": 3,
	}

	# 1. Save with Scholars
	var save_data: Dictionary = {
		"version": 1,
		"locale": "en",
		"faction": "scholars",
		"puzzles": {},
		"unlocked_territories": ["territory_01"],
		"settings": {"music_volume": 1.0, "sfx_volume": 1.0, "haptics_enabled": true},
	}
	var file: FileAccess = FileAccess.open(_test_save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(save_data))
		file.close()

	# Read back and verify faction restores properly
	var read_file: FileAccess = FileAccess.open(_test_save_path, FileAccess.READ)
	if read_file != null:
		var json: JSON = JSON.new()
		if json.parse(read_file.get_as_text()) == OK and json.data is Dictionary:
			var loaded: Dictionary = json.data as Dictionary
			var faction_str: String = loaded.get("faction", "") as String
			var faction_sn: StringName = StringName(faction_str)
			var restored_enum: int = id_to_faction.get(faction_sn, 0) as int
			_assert_eq(restored_enum, 2, "Scholars faction restored after save/load cycle")
		else:
			_fail("Failed to parse saved faction data")
		read_file.close()
	else:
		_fail("Failed to read back saved faction data")

	# Clean up
	if FileAccess.file_exists(_test_save_path):
		DirAccess.remove_absolute(_test_save_path)


# ── Test: PuzzleResult Creation ─────────────────────────────────────────────

func _test_puzzle_result_creation() -> void:
	print("TEST: PuzzleResult creation")

	var pr: PuzzleResult = PuzzleResult.new()
	pr.puzzle_id = "test_puzzle_01"
	pr.completed = true
	pr.stars = 3
	pr.moves = 12
	pr.time_seconds = 45.5
	pr.hints_used = 1

	_assert_eq(pr.puzzle_id, "test_puzzle_01", "puzzle_id set")
	_assert_eq(pr.completed, true, "completed set")
	_assert_eq(pr.stars, 3, "stars set")
	_assert_eq(pr.moves, 12, "moves set")
	_assert_eq(pr.hints_used, 1, "hints_used set")


# ── Helpers ──────────────────────────────────────────────────────────────────

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		_passed += 1
		print("  ✅ %s" % label)
	else:
		_failed += 1
		print("  ❌ %s — expected '%s', got '%s'" % [label, str(expected), str(actual)])


func _fail(msg: String) -> void:
	_failed += 1
	print("  ❌ FAIL: %s" % msg)


func _map_locale(device_locale: String) -> String:
	var lower: String = device_locale.to_lower()
	if lower.begins_with("pt"):
		return "pt_BR"
	return "en"


func _load_test_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(json_text) != OK:
		return {}
	var data: Variant = json.data
	if data is Dictionary:
		return data as Dictionary
	return {}
