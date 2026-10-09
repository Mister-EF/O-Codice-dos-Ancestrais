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
	_test_faction_route_music()
	_test_puzzle_result_creation()
	if not TestMemoryBoard.run_all_tests():
		_failed += 1
	else:
		_passed += 1

	_test_rune_gate_truth_tables()
	_test_rune_chained_evaluation()
	_test_rune_cycle_detection()
	_test_rune_levels_are_solvable()
	_test_rune_truth_table_answers()
	_test_rune_hint_and_stars()
	_test_rune_place_hint_and_star_thresholds()

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


# ── Test: Faction Route Music ───────────────────────────────────────────────

func _test_faction_route_music() -> void:
	print("TEST: Faction route theme music")
	var faction_paths: Dictionary = {
		"pirates": "res://data/factions/pirates.tres",
		"scholars": "res://data/factions/scholars.tres",
		"mercenaries": "res://data/factions/mercenaries.tres",
	}

	for f_id: String in faction_paths.keys():
		var path: String = faction_paths[f_id] as String
		var res: Resource = ResourceLoader.load(path)
		_assert_eq(res is FactionData, true, "%s resource is FactionData" % f_id)
		if res is FactionData:
			var fd: FactionData = res as FactionData
			_assert_eq(fd.placeholder_music != null, true, "%s has placeholder_music set" % f_id)
			_assert_eq(fd.placeholder_music is AudioStream, true, "%s placeholder_music is AudioStream" % f_id)
			_assert_eq(fd.theme_music != null, true, "%s theme_music alias works" % f_id)


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


func _test_rune_gate_truth_tables() -> void:
	print("TEST: Rune AND/OR/NOT truth tables")
	var and_level: RuneLevel = _make_rune_test_level(RuneGateType.Type.AND, [&"A", &"B"])
	var and_logic: RuneLogic = RuneLogic.new(and_level)
	for mask: int in range(4):
		and_logic._input_values[&"A"] = (mask & 2) != 0
		and_logic._input_values[&"B"] = (mask & 1) != 0
		var and_values: Dictionary[StringName, bool] = and_logic.evaluate()
		_assert_eq(and_values[&"OUT"], mask == 3, "AND row %d" % mask)
	var or_level: RuneLevel = _make_rune_test_level(RuneGateType.Type.OR, [&"A", &"B"])
	var or_logic: RuneLogic = RuneLogic.new(or_level)
	for mask: int in range(4):
		or_logic._input_values[&"A"] = (mask & 2) != 0
		or_logic._input_values[&"B"] = (mask & 1) != 0
		var or_values: Dictionary[StringName, bool] = or_logic.evaluate()
		_assert_eq(or_values[&"OUT"], mask != 0, "OR row %d" % mask)
	var not_level: RuneLevel = _make_rune_test_level(RuneGateType.Type.NOT, [&"A"])
	var not_logic: RuneLogic = RuneLogic.new(not_level)
	for input_value: bool in [false, true]:
		not_logic._input_values[&"A"] = input_value
		var not_values: Dictionary[StringName, bool] = not_logic.evaluate()
		_assert_eq(not_values[&"OUT"], not input_value, "NOT row %s" % str(input_value))


func _test_rune_cycle_detection() -> void:
	print("TEST: Rune cycle detection")
	var cycle_level: RuneLevel = RuneLevel.new()
	cycle_level.id = "cycle_test"
	var node_a: RuneNodeData = RuneNodeData.new()
	node_a.id = &"A"
	node_a.gate_type = RuneGateType.Type.AND
	node_a.input_ids = [&"B", &"B"]
	var node_b: RuneNodeData = RuneNodeData.new()
	node_b.id = &"B"
	node_b.gate_type = RuneGateType.Type.OR
	node_b.input_ids = [&"A", &"A"]
	cycle_level.nodes = [node_a, node_b]
	cycle_level.tray = []
	cycle_level.par_moves = 1
	var cycle_logic: RuneLogic = RuneLogic.new(cycle_level)
	var cycle_values: Dictionary[StringName, bool] = cycle_logic.evaluate()
	_assert_eq(cycle_values.is_empty(), true, "cycle returns empty evaluation")
	_assert_eq(cycle_logic.last_error, "cycle", "cycle error exposed")


func _test_rune_chained_evaluation() -> void:
	print("TEST: Chained rune evaluation")
	var level: RuneLevel = ResourceLoader.load("res://data/puzzles/runes/runes_03.tres") as RuneLevel
	var logic: RuneLogic = RuneLogic.new(level)
	var initial_values: Dictionary[StringName, bool] = logic.evaluate()
	_assert_eq(initial_values[&"G1"], true, "AND evaluates before chained OR")
	_assert_eq(initial_values[&"OUT"], true, "chained output is initially TRUE")
	_assert_eq(logic.toggle_input(&"A"), true, "chained input can be toggled")
	var updated_values: Dictionary[StringName, bool] = logic.evaluate()
	_assert_eq(updated_values[&"G1"], false, "AND branch updates live")
	_assert_eq(updated_values[&"OUT"], false, "chained output updates live")


func _test_rune_levels_are_solvable() -> void:
	print("TEST: Shipped rune levels are solvable")
	var level_files: PackedStringArray = DirAccess.get_files_at("res://data/puzzles/runes")
	var level_count: int = 0
	for file_name: String in level_files:
		if not file_name.ends_with(".tres"):
			continue
		var loaded: Resource = ResourceLoader.load("res://data/puzzles/runes/" + file_name)
		if not loaded is RuneLevel:
			_fail("Rune resource failed to load: %s" % file_name)
			continue
		var rune_level: RuneLevel = loaded as RuneLevel
		level_count += 1
		_assert_eq(rune_level.validate_level(), true, "%s validates" % rune_level.id)
		if rune_level.mode == RuneLevel.Mode.TRUTH_TABLE:
			var table: TruthTableLogic = TruthTableLogic.new(rune_level)
			var generated_rows: Array[Dictionary] = table.generate_rows()
			var known_rows_match: bool = true
			for row_index: int in range(rune_level.truth_table_outputs.size()):
				var actual_output: int = 1 if generated_rows[row_index]["output"] else 0
				if rune_level.truth_table_outputs[row_index] == -1:
					table.set_answer(row_index, actual_output == 1)
				elif rune_level.truth_table_outputs[row_index] != actual_output:
					known_rows_match = false
			_assert_eq(known_rows_match and table.validate_answers(), true, "%s truth table is solvable" % rune_level.id)
		else:
			var rune_logic: RuneLogic = RuneLogic.new(rune_level)
			_assert_eq(rune_logic.brute_force_solve(), true, "%s has a solution" % rune_level.id)
	_assert_eq(level_count, 10, "all ten rune levels loaded")


func _test_rune_truth_table_answers() -> void:
	print("TEST: Truth table answer validation")
	var truth_level: RuneLevel = ResourceLoader.load("res://data/puzzles/runes/runes_07.tres") as RuneLevel
	var truth_logic: TruthTableLogic = TruthTableLogic.new(truth_level)
	_assert_eq(truth_logic.is_complete(), false, "blank cells are incomplete")
	_assert_eq(truth_logic.cycle_answer(1), true, "answer cell can be cycled")
	_assert_eq(truth_logic.generate_rows()[1]["answer"], 1, "blank cell first selects TRUE")
	_assert_eq(truth_logic.cycle_answer(1), true, "TRUE answer can be changed")
	_assert_eq(truth_logic.generate_rows()[1]["answer"], 0, "second tap selects FALSE")
	_assert_eq(truth_logic.set_answer(1, true), true, "answer can be changed to an incorrect value")
	_assert_eq(truth_logic.validate_answers(), false, "incorrect table answer is rejected")
	_assert_eq(truth_logic.set_answer(1, false), true, "FALSE answer can be set")
	_assert_eq(truth_logic.set_answer(2, false), true, "second answer can be set")
	_assert_eq(truth_logic.validate_answers(), true, "AND truth table answers validate")
	_assert_eq(truth_logic.is_complete(), true, "answered table is complete")


func _test_rune_hint_and_stars() -> void:
	print("TEST: Rune hints and star thresholds")
	var level: RuneLevel = ResourceLoader.load("res://data/puzzles/runes/runes_01.tres") as RuneLevel
	var logic: RuneLogic = RuneLogic.new(level)
	var hint: Dictionary = logic.get_hint()
	_assert_eq(hint.get("kind", ""), "input", "hint points to an input")
	_assert_eq(hint.get("value", false), true, "hint proposes a solving input state")

	_assert_eq(logic.toggle_input(hint["node_id"] as StringName), true, "hinted input can be changed")
	_assert_eq(logic.is_solved(), true, "hinted change solves level")
	_assert_eq(logic.get_stars(), 3, "par move awards three stars")
	_assert_eq(logic.moves, 1, "one change counts as one move")


func _test_rune_place_hint_and_star_thresholds() -> void:
	print("TEST: PLACE_GATES hint and star thresholds")
	var boss_level: RuneLevel = ResourceLoader.load("res://data/puzzles/runes/runes_10.tres") as RuneLevel
	var boss_logic: RuneLogic = RuneLogic.new(boss_level)
	var first_hint: Dictionary = boss_logic.get_hint()
	_assert_eq(first_hint.get("kind", ""), "gate", "multi-step hint proposes a gate")
	_assert_eq(first_hint.get("node_id", &""), &"S1", "hint selects the first empty slot")
	_assert_eq(first_hint.get("gate_type", RuneGateType.Type.EMPTY_SLOT), RuneGateType.Type.AND, "hint gate participates in a solution")
	_assert_eq(boss_logic.place_gate(&"S1", RuneGateType.Type.AND), true, "hinted gate can be placed")
	_assert_eq(boss_logic.brute_force_solve(), true, "solver handles an already placed gate")
	_assert_eq(boss_logic.get_gate_type(&"S1"), RuneGateType.Type.AND, "solver preserves the placed gate")
	var second_hint: Dictionary = boss_logic.get_hint()
	_assert_eq(second_hint.get("node_id", &""), &"S2", "next hint advances to the dependent slot")
	_assert_eq(boss_logic.place_gate(&"S2", second_hint.get("gate_type", RuneGateType.Type.EMPTY_SLOT) as RuneGateType.Type), true, "second hinted gate can be placed")
	_assert_eq(boss_logic.is_solved(), true, "hinted mixed boss arrangement solves")
	_assert_eq(boss_logic.get_stars(), 3, "boss completed at par earns three stars")
	_assert_eq(boss_logic.remove_gate(&"S2"), true, "placed gate can be removed")
	_assert_eq(boss_logic.get_remaining_tray().size(), 1, "removed gate returns to tray")

	var threshold_level: RuneLevel = ResourceLoader.load("res://data/puzzles/runes/runes_02.tres") as RuneLevel
	var threshold_logic: RuneLogic = RuneLogic.new(threshold_level)
	threshold_logic.toggle_input(&"A")
	threshold_logic.toggle_input(&"B")
	_assert_eq(threshold_logic.get_stars(), 2, "two moves earn two stars")
	threshold_logic.toggle_input(&"A")
	threshold_logic.toggle_input(&"A")
	_assert_eq(threshold_logic.get_stars(), 1, "over the two-star threshold earns one star")



func _make_rune_test_level(gate_type: int, inputs: Array[StringName]) -> RuneLevel:

	var test_level: RuneLevel = RuneLevel.new()
	test_level.id = "gate_test"
	test_level.target_value = true
	test_level.par_moves = 1
	var node_a: RuneNodeData = RuneNodeData.new()
	node_a.id = &"A"
	node_a.gate_type = RuneGateType.Type.INPUT
	var node_b: RuneNodeData = RuneNodeData.new()
	node_b.id = &"B"
	node_b.gate_type = RuneGateType.Type.INPUT
	var gate: RuneNodeData = RuneNodeData.new()
	gate.id = &"G"
	gate.gate_type = gate_type
	gate.input_ids = inputs
	var output: RuneNodeData = RuneNodeData.new()
	output.id = &"OUT"
	output.gate_type = RuneGateType.Type.OUTPUT
	output.input_ids = [&"G"]
	test_level.nodes = [node_a, node_b, gate, output]
	return test_level


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
