## Headless unit test runner for Memory Board logic.
class_name TestMemoryBoard
extends RefCounted

static func run_all_tests() -> bool:
	var all_passed: bool = true
	print("--- Running TestMemoryBoard ---")
	
	if not test_load_and_shuffle():
		all_passed = false
	if not test_flip_match_and_mismatch():
		all_passed = false
	if not test_completion_and_stars():
		all_passed = false
	if not test_faction_bonus_and_hint():
		all_passed = false
		
	if all_passed:
		print("✅ ALL Memory Board logic tests passed!")
	else:
		push_error("❌ Some Memory Board logic tests failed!")
	return all_passed

static func _create_dummy_level() -> MemoryBoardLevel:
	var lvl: MemoryBoardLevel = MemoryBoardLevel.new()
	lvl.id = "test_memory_01"
	lvl.grid_columns = 2
	lvl.grid_rows = 2
	lvl.concept_ids = [&"docker", &"git"]
	lvl.star_thresholds = [2, 4, 6]
	return lvl

static func test_load_and_shuffle() -> bool:
	var logic: MemoryBoardLogic = MemoryBoardLogic.new()
	var lvl: MemoryBoardLevel = _create_dummy_level()
	logic.load_level(lvl, 12345)
	
	if logic.cards.size() != 4:
		print("FAIL: Expected 4 cards, got ", logic.cards.size())
		return false
		
	if logic.total_pairs != 2:
		print("FAIL: Expected 2 pairs, got ", logic.total_pairs)
		return false
		
	print("PASS: test_load_and_shuffle")
	return true

static func test_flip_match_and_mismatch() -> bool:
	var logic: MemoryBoardLogic = MemoryBoardLogic.new()
	var lvl: MemoryBoardLevel = _create_dummy_level()
	logic.load_level(lvl, 12345)
	
	# First flip
	var r1: Dictionary = logic.flip(0)
	if not r1.get("success", false) or logic.state != MemoryBoardLogic.State.ONE_FACE_UP:
		print("FAIL: First flip should set state to ONE_FACE_UP")
		return false
		
	# Find a matching or mismatching card for index 0
	var c0: MemoryBoardLogic.CardItem = logic.cards[0]
	var other_match_idx: int = -1
	var mismatch_idx: int = -1
	for i in range(1, logic.cards.size()):
		if logic.cards[i].pair_id == c0.pair_id:
			other_match_idx = i
		else:
			mismatch_idx = i
			
	# Test mismatch
	var r2: Dictionary = logic.flip(mismatch_idx)
	if not r2.get("success", false) or logic.state != MemoryBoardLogic.State.RESOLVING:
		print("FAIL: Second mismatch flip should set state to RESOLVING")
		return false
		
	var reset_indices: Array[int] = logic.resolve_mismatch()
	if reset_indices.size() != 2 or logic.state != MemoryBoardLogic.State.IDLE:
		print("FAIL: resolve_mismatch should return 2 indices and reset state to IDLE")
		return false
		
	# Test match
	logic.flip(0)
	var r3: Dictionary = logic.flip(other_match_idx)
	if not r3.get("matched", false):
		print("FAIL: Flipping matching pair should report matched=true")
		return false
		
	print("PASS: test_flip_match_and_mismatch")
	return true

static func test_completion_and_stars() -> bool:
	var logic: MemoryBoardLogic = MemoryBoardLogic.new()
	var lvl: MemoryBoardLevel = _create_dummy_level()
	logic.load_level(lvl, 100)
	
	# Find pair 1 and pair 2
	var pair_map: Dictionary = {}
	for c in logic.cards:
		if not pair_map.has(c.pair_id):
			pair_map[c.pair_id] = []
		pair_map[c.pair_id].append(c.index)
		
	var keys: Array = pair_map.keys()
	var p1: Array = pair_map[keys[0]]
	var p2: Array = pair_map[keys[1]]
	
	logic.flip(p1[0])
	logic.flip(p1[1])
	logic.flip(p2[0])
	var res: Dictionary = logic.flip(p2[1])
	
	if not res.get("complete", false) or logic.state != MemoryBoardLogic.State.COMPLETE:
		print("FAIL: Board should be COMPLETE after matching all pairs")
		return false
		
	var stars: int = logic.calculate_stars()
	if stars != 3:
		print("FAIL: Expected 3 stars for 2 moves (threshold <= 2), got ", stars)
		return false
		
	print("PASS: test_completion_and_stars")
	return true

static func test_faction_bonus_and_hint() -> bool:
	var logic: MemoryBoardLogic = MemoryBoardLogic.new()
	var lvl: MemoryBoardLevel = _create_dummy_level()
	lvl.star_thresholds = [2, 4, 6]
	logic.load_level(lvl, 50, 2) # 2 extra flips bonus
	
	logic.moves = 4 # Normally 2 stars, but with 2 bonus flips effective moves = 2 => 3 stars
	if logic.calculate_stars() != 3:
		print("FAIL: Faction bonus extra flips should improve star rating calculation")
		return false
		
	var hint_pair: Array[int] = logic.get_hint_pair()
	if hint_pair.size() != 2:
		print("FAIL: Hint pair should return 2 card indices")
		return false
		
	print("PASS: test_faction_bonus_and_hint")
	return true
