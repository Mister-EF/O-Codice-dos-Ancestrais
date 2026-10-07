## TestCircuitPuzzle — Comprehensive headless test suite for the Circuit Puzzle logic,
## BFS flow propagation, rotation masks, blocker behavior, solver validation, hints, and star ratings.
class_name TestCircuitPuzzle
extends RefCounted


var _pass_count: int = 0
var _fail_count: int = 0


func run_all() -> bool:
	_pass_count = 0
	_fail_count = 0
	print("--- Running TestCircuitPuzzle ---")

	test_rotation_masks()
	test_connection_symmetry()
	test_bfs_flood_fill()
	test_blocker_and_empty_behavior()
	test_locked_tiles()
	test_solved_detection()
	test_hint_generation()
	test_star_calculation()
	test_all_eight_levels_solvable()
	save_all_level_resources()

	print("--- TestCircuitPuzzle Finished: %d passed, %d failed ---" % [_pass_count, _fail_count])
	return _fail_count == 0


func _assert_true(cond: bool, test_name: String) -> void:
	if cond:
		_pass_count += 1
	else:
		_fail_count += 1
		push_error("FAILED: %s" % test_name)


# ── 1. Rotation Masks ────────────────────────────────────────────────────────

func test_rotation_masks() -> void:
	# Straight base: N (1) | S (4) = 5
	var str_base: int = CircuitTileDef.get_base_mask(CircuitTileDef.CircuitTileType.STRAIGHT)
	_assert_true(str_base == 5, "Straight base mask is N|S (5)")
	_assert_true(CircuitTileDef.rotate_mask(str_base, 1) == 10, "Straight rotated 90 is E|W (10)")
	_assert_true(CircuitTileDef.rotate_mask(str_base, 2) == 5, "Straight rotated 180 is N|S (5)")
	_assert_true(CircuitTileDef.rotate_mask(str_base, 3) == 10, "Straight rotated 270 is E|W (10)")

	# Corner base: N (1) | E (2) = 3
	var crn_base: int = CircuitTileDef.get_base_mask(CircuitTileDef.CircuitTileType.CORNER)
	_assert_true(crn_base == 3, "Corner base mask is N|E (3)")
	_assert_true(CircuitTileDef.rotate_mask(crn_base, 1) == 6, "Corner rotated 90 is E|S (6)")
	_assert_true(CircuitTileDef.rotate_mask(crn_base, 2) == 12, "Corner rotated 180 is S|W (12)")
	_assert_true(CircuitTileDef.rotate_mask(crn_base, 3) == 9, "Corner rotated 270 is W|N (9)")

	# T-Junction base: N (1) | E (2) | S (4) = 7
	var t_base: int = CircuitTileDef.get_base_mask(CircuitTileDef.CircuitTileType.T_JUNCTION)
	_assert_true(t_base == 7, "T-junction base mask is N|E|S (7)")
	_assert_true(CircuitTileDef.rotate_mask(t_base, 1) == 14, "T-junction rot 90 is E|S|W (14)")
	_assert_true(CircuitTileDef.rotate_mask(t_base, 2) == 13, "T-junction rot 180 is S|W|N (13)")
	_assert_true(CircuitTileDef.rotate_mask(t_base, 3) == 11, "T-junction rot 270 is W|N|E (11)")

	# Cross: 15 in all rotations
	var crs_base: int = CircuitTileDef.get_base_mask(CircuitTileDef.CircuitTileType.CROSS)
	_assert_true(crs_base == 15, "Cross base mask is 15")
	_assert_true(CircuitTileDef.rotate_mask(crs_base, 1) == 15, "Cross rot 90 is 15")


# ── 2. Connection Symmetry ───────────────────────────────────────────────────

func test_connection_symmetry() -> void:
	# Hand-crafted 2x1 grid: (0,0) Source pointing East, (1,0) Target pointing West -> connected
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.grid_columns = 2
	lvl.grid_rows = 1
	lvl.required_targets = 1
	lvl.tiles = [
		CircuitLevelBuilder.tile(CircuitTileDef.CircuitTileType.SOURCE, 1, 1), # East
		CircuitLevelBuilder.tile(CircuitTileDef.CircuitTileType.TARGET, 3, 3), # West
	]
	var logic: CircuitLogic = CircuitLogic.new()
	logic.load_level(lvl)
	var pw: Dictionary = logic.compute_powered()
	_assert_true(pw[Vector2i(0, 0)] == true, "Source is powered")
	_assert_true(pw[Vector2i(1, 0)] == true, "Target connected symmetrically is powered")

	# Now rotate target so it points North (rot 0):
	logic.set_tile_rotation(Vector2i(1, 0), 0)
	pw = logic.compute_powered()
	_assert_true(pw[Vector2i(1, 0)] == false, "Target pointing North is NOT powered (asymmetrical)")


# ── 3. BFS Flood Fill ────────────────────────────────────────────────────────

func test_bfs_flood_fill() -> void:
	# 3x1 line: Source East -> Straight EW -> Target West
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.grid_columns = 3
	lvl.grid_rows = 1
	lvl.required_targets = 1
	lvl.tiles = [
		CircuitLevelBuilder.tile(CircuitTileDef.CircuitTileType.SOURCE, 1, 1),
		CircuitLevelBuilder.tile(CircuitTileDef.CircuitTileType.STRAIGHT, 1, 1),
		CircuitLevelBuilder.tile(CircuitTileDef.CircuitTileType.TARGET, 3, 3),
	]
	var logic: CircuitLogic = CircuitLogic.new()
	logic.load_level(lvl)
	_assert_true(logic.is_solved(), "Line circuit solved")

	# Break connection in middle: rotate straight to NS (rot 0)
	logic.set_tile_rotation(Vector2i(1, 0), 0)
	_assert_true(not logic.is_solved(), "Line circuit broken when middle rotated")


# ── 4. Blocker and Empty Behavior ────────────────────────────────────────────

func test_blocker_and_empty_behavior() -> void:
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.grid_columns = 3
	lvl.grid_rows = 1
	lvl.required_targets = 1
	lvl.tiles = [
		CircuitLevelBuilder.tile(CircuitTileDef.CircuitTileType.SOURCE, 1, 1),
		CircuitLevelBuilder.tile(CircuitTileDef.CircuitTileType.BLOCKER, 0, 0),
		CircuitLevelBuilder.tile(CircuitTileDef.CircuitTileType.TARGET, 3, 3),
	]
	var logic: CircuitLogic = CircuitLogic.new()
	logic.load_level(lvl)
	var pw: Dictionary = logic.compute_powered()
	_assert_true(pw[Vector2i(1, 0)] == false, "Blocker never conducts")
	_assert_true(pw[Vector2i(2, 0)] == false, "Target behind blocker is not powered")
	_assert_true(not logic.rotate_tile(Vector2i(1, 0)), "Blocker cannot be rotated")


# ── 5. Locked Tiles ──────────────────────────────────────────────────────────

func test_locked_tiles() -> void:
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.grid_columns = 1
	lvl.grid_rows = 1
	lvl.tiles = [
		CircuitLevelBuilder.tile(CircuitTileDef.CircuitTileType.STRAIGHT, 0, 0, true)
	]
	var logic: CircuitLogic = CircuitLogic.new()
	logic.load_level(lvl)
	_assert_true(not logic.rotate_tile(Vector2i(0, 0)), "Locked tile cannot be rotated")
	_assert_true(logic.moves == 0, "No moves counted when tapping locked tile")


# ── 6. Solved Detection ──────────────────────────────────────────────────────

func test_solved_detection() -> void:
	var lvl: CircuitLevel = CircuitLevelBuilder.build_level_1()
	var logic: CircuitLogic = CircuitLogic.new()
	logic.load_level(lvl)

	# Initially scrambled in build_level_1 (or check with solution)
	for y: int in range(lvl.grid_rows):
		for x: int in range(lvl.grid_columns):
			var cell: Vector2i = Vector2i(x, y)
			var def: CircuitTileDef = lvl.get_tile_def(cell)
			if def != null:
				logic.set_tile_rotation(cell, def.solution_rotation)

	_assert_true(logic.is_solved(), "Level 1 is solved with authored solution")


# ── 7. Hint Generation ───────────────────────────────────────────────────────

func test_hint_generation() -> void:
	var lvl: CircuitLevel = CircuitLevelBuilder.build_level_1()
	var logic: CircuitLogic = CircuitLogic.new()
	logic.load_level(lvl)

	# Apply solution to all
	for y: int in range(lvl.grid_rows):
		for x: int in range(lvl.grid_columns):
			var cell: Vector2i = Vector2i(x, y)
			var def: CircuitTileDef = lvl.get_tile_def(cell)
			if def != null:
				logic.set_tile_rotation(cell, def.solution_rotation)

	# Misorient cell (1, 0)
	logic.set_tile_rotation(Vector2i(1, 0), 0) # Solution is 1
	var hint: Vector2i = logic.get_hint()
	_assert_true(hint == Vector2i(1, 0), "Hint points to wrongly oriented cell")


# ── 8. Star Calculation ──────────────────────────────────────────────────────

func test_star_calculation() -> void:
	var lvl: CircuitLevel = CircuitLevel.new()
	lvl.grid_columns = 1
	lvl.grid_rows = 1
	lvl.required_targets = 0 # No targets needed, immediately solved if source
	lvl.par_moves = 5
	lvl.star_thresholds = [5, 8, 12]
	lvl.tiles = [CircuitLevelBuilder.tile(CircuitTileDef.CircuitTileType.SOURCE, 0, 0)]

	var logic: CircuitLogic = CircuitLogic.new()
	logic.load_level(lvl)

	# 0 moves -> 3 stars
	_assert_true(logic.calculate_stars() == 3, "3 stars for moves <= 5")
	logic.moves = 7
	_assert_true(logic.calculate_stars() == 2, "2 stars for moves <= 8")
	logic.moves = 10
	_assert_true(logic.calculate_stars() == 1, "1 star for moves <= 12")
	logic.moves = 20
	_assert_true(logic.calculate_stars() == 1, "1 star minimum for completion")


# ── 9. All 8 Levels Solvable ─────────────────────────────────────────────────

func test_all_eight_levels_solvable() -> void:
	var all_levels: Array[CircuitLevel] = CircuitLevelBuilder.get_all_levels()
	_assert_true(all_levels.size() == 8, "Exactly 8 levels built")

	for i: int in range(all_levels.size()):
		var lvl: CircuitLevel = all_levels[i]
		var solvable: bool = CircuitSolver.validate_authored_solution(lvl)
		_assert_true(solvable, "Level %s authored solution is valid and solves puzzle" % lvl.id)

		# Test scrambling with seed
		CircuitSolver.shuffle_from_solution(lvl, 1000 + i)
		var test_logic: CircuitLogic = CircuitLogic.new()
		test_logic.load_level(lvl)
		var hint_after_scramble: Vector2i = test_logic.get_hint()
		_assert_true(hint_after_scramble != Vector2i(-1, -1), "Level %s has wrong tiles after scramble" % lvl.id)


# ── 10. Save All Levels to res://data/puzzles/circuit/ ───────────────────────

func save_all_level_resources() -> void:
	var dir_path: String = "res://data/puzzles/circuit"
	var dir: DirAccess = DirAccess.open("res://data/puzzles")
	if dir != null and not dir.dir_exists("circuit"):
		dir.make_dir("circuit")

	var all_levels: Array[CircuitLevel] = CircuitLevelBuilder.get_all_levels()
	for lvl: CircuitLevel in all_levels:
		var file_path: String = "%s/%s.tres" % [dir_path, lvl.id]
		var err: Error = ResourceSaver.save(lvl, file_path)
		_assert_true(err == OK, "Saved level resource %s" % file_path)
