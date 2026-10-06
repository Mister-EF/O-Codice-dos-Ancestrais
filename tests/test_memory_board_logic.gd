## Headless unit tests for the pure memory-board rules.
## Run with: godot --headless -s res://tests/test_memory_board_logic.gd
extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_test_seeded_shuffle()
	_test_match_and_mismatch()
	_test_completion_and_stars()
	_test_faction_bonuses()
	_test_rapid_repeated_flips()
	_test_hint_tracking()
	_test_level_resources()
	print("\nMemoryBoardLogic: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_seeded_shuffle() -> void:
	print("TEST: deterministic seeded shuffle")
	var level: MemoryBoardLevel = _load_level(1)
	var first: MemoryBoardLogic = MemoryBoardLogic.new()
	var second: MemoryBoardLogic = MemoryBoardLogic.new()
	_check(first.setup(level, 8231), "first seeded deck builds")
	_check(second.setup(level, 8231), "second seeded deck builds")
	_check(first.deck.size() == second.deck.size(), "seeded deck sizes match")
	for index: int in range(mini(first.deck.size(), second.deck.size())):
		_check(
			first.deck[index].pair_id == second.deck[index].pair_id
			and first.deck[index].card_type == second.deck[index].card_type,
			"seeded card %d matches" % index
		)


func _test_match_and_mismatch() -> void:
	print("TEST: matching and mismatching flips")
	var logic: MemoryBoardLogic = MemoryBoardLogic.new()
	_check(logic.setup(_load_level(1), 7), "level builds for match test")
	var first_pair: Array[int] = _indices_for_pair(logic, logic.deck[0].pair_id)
	var other_pair: Array[int] = _indices_for_different_pair(logic, logic.deck[0].pair_id)
	var first_flip: FlipResult = logic.flip(first_pair[0])
	_check(first_flip.accepted and first_flip.state == MemoryBoardLogic.BoardState.ONE_FACE_UP, "first flip is accepted")
	var duplicate_flip: FlipResult = logic.flip(first_pair[0])
	_check(not duplicate_flip.accepted, "same face-up card cannot be flipped twice")
	var mismatch: FlipResult = logic.flip(other_pair[0])
	_check(mismatch.mismatch and mismatch.state == MemoryBoardLogic.BoardState.RESOLVING, "different concepts enter resolving state")
	_check(logic.moves == 1, "mismatch counts as one move")
	_check(not logic.flip(first_pair[1]).accepted, "flips are ignored while resolving")
	logic.resolve_mismatch()
	var matching_first: FlipResult = logic.flip(first_pair[0])
	var matching_second: FlipResult = logic.flip(first_pair[1])
	_check(matching_first.accepted and matching_second.matched, "same pair with two card types matches")
	_check(logic.is_pair_matched(logic.deck[first_pair[0]].pair_id), "matched pair is recorded")


func _test_completion_and_stars() -> void:
	print("TEST: full completion and star thresholds")
	var logic: MemoryBoardLogic = MemoryBoardLogic.new()
	_check(logic.setup(_load_level(1), 17), "level builds for completion test")
	_play_all_pairs(logic)
	_check(logic.state == MemoryBoardLogic.BoardState.COMPLETE, "all pairs complete the board")
	_check(logic.calculate_stars() == 3, "efficient completion awards three stars")

	var two_star_logic: MemoryBoardLogic = MemoryBoardLogic.new()
	_check(two_star_logic.setup(_load_level(1), 17), "level builds for threshold test")
	two_star_logic.moves = 2
	_play_all_pairs(two_star_logic)
	_check(two_star_logic.moves == 5, "threshold test reaches two-star move count")
	_check(two_star_logic.calculate_stars() == 2, "two-star threshold is applied")

	var one_star_logic: MemoryBoardLogic = MemoryBoardLogic.new()
	_check(one_star_logic.setup(_load_level(1), 17), "level builds for one-star threshold test")
	one_star_logic.moves = 4
	_play_all_pairs(one_star_logic)
	_check(one_star_logic.calculate_stars() == 1, "completed level awards one star above the two-star threshold")


func _test_faction_bonuses() -> void:
	print("TEST: injected faction bonuses")
	var level: MemoryBoardLevel = _load_level(3)
	var bonus: FactionData = FactionData.new()
	bonus.extra_flip_allowance = 2
	bonus.time_bonus_seconds = 15.0
	var logic: MemoryBoardLogic = MemoryBoardLogic.new()
	_check(logic.setup(level, 12, bonus), "level builds with faction data")
	_check(logic.effective_max_moves == level.max_moves + 2, "extra allowed moves are applied")
	_check(
		is_equal_approx(logic.effective_time_limit_seconds, level.time_limit_seconds + 15.0),
		"extra time is applied"
	)
	var untimed_level: MemoryBoardLevel = _load_level(1)
	var untimed_logic: MemoryBoardLogic = MemoryBoardLogic.new()
	_check(untimed_logic.setup(untimed_level, 12, bonus), "untimed level builds")
	_check(untimed_logic.effective_time_limit_seconds == 0.0, "bonus does not add a limit to untimed levels")


func _test_rapid_repeated_flips() -> void:
	print("TEST: rapid repeated and invalid flips")
	var logic: MemoryBoardLogic = MemoryBoardLogic.new()
	_check(logic.setup(_load_level(1), 9), "level builds for rapid-flip test")
	_check(not logic.flip(-1).accepted, "negative index is ignored")
	_check(not logic.flip(logic.deck.size()).accepted, "out-of-range index is ignored")
	var first: FlipResult = logic.flip(0)
	var repeated: FlipResult = logic.flip(0)
	_check(first.accepted and not repeated.accepted, "rapid duplicate input does not corrupt state")
	_check(logic.state == MemoryBoardLogic.BoardState.ONE_FACE_UP, "rapid input preserves the state machine")


func _test_hint_tracking() -> void:
	print("TEST: hint allowance and usage tracking")
	var logic: MemoryBoardLogic = MemoryBoardLogic.new()
	_check(logic.setup(_load_level(1), 19), "level builds for hint test")
	var hinted_pair: Array[int] = logic.reveal_hint_pair()
	_check(hinted_pair.size() == 2, "hint reveals one unmatched pair")
	_check(logic.hints_used == 1, "hint use is counted")
	_check(logic.reveal_hint_pair().is_empty(), "hint allowance is enforced")


func _test_level_resources() -> void:
	print("TEST: six authored level resources")
	for index: int in range(1, 7):
		var level: MemoryBoardLevel = _load_level(index)
		_check(level != null, "memory level %02d loads" % index)
		if level == null:
			continue
		_check(
			level.grid_columns * level.grid_rows == level.concept_ids.size() * 2,
			"memory level %02d has matching grid and deck size" % index
		)
		var logic: MemoryBoardLogic = MemoryBoardLogic.new()
		_check(logic.setup(level, index), "memory level %02d produces a deck" % index)
		if index == 5:
			_check(_all_pairs_use_icon(logic), "icon mode pairs every concept with an icon")
		elif index == 4:
			_check(_mixed_deck_has_both_partner_types(logic), "mixed mode includes definitions and icons")


func _load_level(index: int) -> MemoryBoardLevel:
	var path: String = "res://data/puzzles/memory/memory_%02d.tres" % index
	var level: MemoryBoardLevel = load(path) as MemoryBoardLevel
	if level == null:
		_fail("Cannot load %s" % path)
	return level


func _indices_for_pair(logic: MemoryBoardLogic, pair_id: StringName) -> Array[int]:
	var indices: Array[int] = []
	for index: int in range(logic.deck.size()):
		if logic.deck[index].pair_id == pair_id:
			indices.append(index)
	return indices


func _indices_for_different_pair(logic: MemoryBoardLogic, pair_id: StringName) -> Array[int]:
	for index: int in range(logic.deck.size()):
		if logic.deck[index].pair_id != pair_id:
			return _indices_for_pair(logic, logic.deck[index].pair_id)
	return []


func _play_all_pairs(logic: MemoryBoardLogic) -> void:
	var played: Dictionary = {}
	for index: int in range(logic.deck.size()):
		var pair_id: StringName = logic.deck[index].pair_id
		if played.has(pair_id):
			continue
		played[pair_id] = true
		var indices: Array[int] = _indices_for_pair(logic, pair_id)
		if indices.size() == 2:
			logic.flip(indices[0])
			logic.flip(indices[1])


func _all_pairs_use_icon(logic: MemoryBoardLogic) -> bool:
	for pair_id: StringName in logic.level.concept_ids:
		var indices: Array[int] = _indices_for_pair(logic, pair_id)
		if indices.size() != 2:
			return false
		if logic.deck[indices[0]].card_type == logic.deck[indices[1]].card_type:
			return false
		var partner_type: int = logic.deck[indices[0]].card_type
		if partner_type == MemoryCardData.CardType.NAME:
			partner_type = logic.deck[indices[1]].card_type
		if partner_type != MemoryCardData.CardType.ICON:
			return false
	return true


func _mixed_deck_has_both_partner_types(logic: MemoryBoardLogic) -> bool:
	var has_definition: bool = false
	var has_icon: bool = false
	for pair_id: StringName in logic.level.concept_ids:
		var indices: Array[int] = _indices_for_pair(logic, pair_id)
		for index: int in indices:
			has_definition = has_definition or logic.deck[index].card_type == MemoryCardData.CardType.DEFINITION
			has_icon = has_icon or logic.deck[index].card_type == MemoryCardData.CardType.ICON
	return has_definition and has_icon


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % description)
	else:
		_fail(description)


func _fail(description: String) -> void:
	_failed += 1
	push_error("FAIL: %s" % description)
