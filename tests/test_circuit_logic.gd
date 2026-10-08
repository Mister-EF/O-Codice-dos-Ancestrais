## Headless tests for the pure circuit puzzle rules.
## Run with: godot --headless -s res://tests/test_circuit_logic.gd
extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_test_rotation_masks()
	_test_edge_symmetry_and_bfs()
	_test_blocker_and_locked_tiles()
	_test_solved_hint_and_moves()
	_test_stars()
	_test_shipped_levels_are_solvable()
	_test_seeded_shuffle()
	print("\nCircuitLogic: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_rotation_masks() -> void:
	print("TEST: rotation masks for every tile type")
	_check(CircuitLogic.mask_for_type(CircuitTileDef.TileType.EMPTY, 0) == 0, "empty has no connections")
	_check(CircuitLogic.mask_for_type(CircuitTileDef.TileType.STRAIGHT, 0) == 5, "straight north-south")
	_check(CircuitLogic.mask_for_type(CircuitTileDef.TileType.STRAIGHT, 1) == 10, "straight rotates east-west")
	_check(CircuitLogic.mask_for_type(CircuitTileDef.TileType.CORNER, 0) == 3, "corner north-east")
	_check(CircuitLogic.mask_for_type(CircuitTileDef.TileType.CORNER, 1) == 6, "corner east-south")
	_check(CircuitLogic.mask_for_type(CircuitTileDef.TileType.T_JUNCTION, 0) == 11, "T junction has three edges")
	_check(CircuitLogic.mask_for_type(CircuitTileDef.TileType.T_JUNCTION, 1) == 7, "T junction rotates clockwise")
	_check(CircuitLogic.mask_for_type(CircuitTileDef.TileType.CROSS, 3) == 15, "cross remains connected in every direction")
	_check(CircuitLogic.mask_for_type(CircuitTileDef.TileType.SOURCE, 1) == CircuitLogic.EAST, "source port rotates")
	_check(CircuitLogic.mask_for_type(CircuitTileDef.TileType.TARGET, 2) == CircuitLogic.SOUTH, "target port rotates")
	_check(CircuitLogic.mask_for_type(CircuitTileDef.TileType.BLOCKER, 0) == 0, "blocker has no connections")


func _test_edge_symmetry_and_bfs() -> void:
	print("TEST: reciprocal edges and BFS powering")
	var level: CircuitLevel = _linear_level(false)
	var logic: CircuitLogic = CircuitLogic.new()
	_check(logic.setup(level), "linear test level sets up")
	_check(logic.compute_powered().size() == 1, "one-sided edge does not power its neighbor")
	logic.rotations[Vector2i(1, 0)] = 1
	_check(logic.is_solved(), "BFS powers straight path when both sides connect")
	_check(logic.compute_powered().size() == 3, "BFS reaches all connected cells")
	_check(logic.get_powered_order().size() == 3, "powered order contains full route")
	logic.rotations[Vector2i(2, 0)] = 0
	_check(not logic.is_solved(), "target does not connect through its closed edge")


func _test_blocker_and_locked_tiles() -> void:
	print("TEST: blocker behavior and locked rotation")
	var level: CircuitLevel = CircuitLevel.new()
	level.id = "test_blocker"
	level.grid_columns = 3
	level.grid_rows = 1
	var tiles: Array[CircuitTileDef] = [
		_make_tile(Vector2i(0, 0), CircuitTileDef.TileType.SOURCE, 1, 1),
		_make_tile(Vector2i(1, 0), CircuitTileDef.TileType.BLOCKER, 0, 0),
		_make_tile(Vector2i(2, 0), CircuitTileDef.TileType.TARGET, 3, 3),
	]
	level.tiles = tiles
	level.required_targets = [Vector2i(2, 0)]
	var logic: CircuitLogic = CircuitLogic.new()
	_check(logic.setup(level), "blocker level sets up")
	_check(not logic.is_solved(), "blocker prevents signal propagation")
	var locked: CircuitTileDef = _make_tile(Vector2i(1, 0), CircuitTileDef.TileType.STRAIGHT, 1, 1)
	locked.locked = true
	var lock_level: CircuitLevel = CircuitLevel.new()
	lock_level.id = "test_locked"
	lock_level.grid_columns = 3
	lock_level.grid_rows = 1
	lock_level.tiles = [
		_make_tile(Vector2i(0, 0), CircuitTileDef.TileType.SOURCE, 1, 1),
		locked,
		_make_tile(Vector2i(2, 0), CircuitTileDef.TileType.TARGET, 3, 3),
	]
	lock_level.required_targets = [Vector2i(2, 0)]
	_check(logic.setup(lock_level), "locked-tile level sets up")
	logic.rotate_tile(Vector2i(1, 0))
	_check(logic.rotations[Vector2i(1, 0)] == 1 and logic.moves == 0, "locked tile cannot rotate or cost a move")


func _test_solved_hint_and_moves() -> void:
	print("TEST: solved detection, hints, and move counter")
	var level: CircuitLevel = load("res://data/puzzles/circuit/circuit_01.tres") as CircuitLevel
	var logic: CircuitLogic = CircuitLogic.new()
	_check(logic.setup(level), "shipped level sets up")
	_check(not logic.is_solved(), "scrambled level begins unsolved")
	var hint: Vector2i = logic.get_hint()
	_check(hint != CircuitLogic.INVALID_CELL, "hint returns a valid misoriented tile")
	_check(logic.register_hint(), "hint can be recorded")
	_check(logic.hints_used == 1 and logic.moves == 0, "hint use is tracked separately from rotations")
	logic.rotate_tile(hint)
	_check(logic.moves == 2, "rotating a tile increments moves")
	logic.set_solution_layout()
	_check(logic.is_solved(), "authored solution powers all required targets")
	_check(logic.get_hint() == CircuitLogic.INVALID_CELL, "solved layout has no hint")
	var scholars: FactionData = FactionData.new()
	scholars.hint_discount = 100
	_check(logic.setup(level, scholars), "faction bonus level setup succeeds")
	_check(is_zero_approx(logic.hint_move_cost), "full hint discount removes the star penalty")
	_check(logic.register_hint() and logic.moves == 0, "discounted hint is tracked without altering moves")


func _test_stars() -> void:
	print("TEST: star thresholds")
	var level: CircuitLevel = _linear_level(true)
	level.three_star_moves = 3
	level.two_star_moves = 5
	level.one_star_moves = 8
	var logic: CircuitLogic = CircuitLogic.new()
	_check(logic.setup(level), "star test level sets up")
	logic.set_solution_layout()
	_check(logic.calculate_stars() == 3, "par threshold awards three stars")
	logic.moves = 5
	_check(logic.calculate_stars() == 2, "two-star threshold is applied")
	logic.moves = 8
	_check(logic.calculate_stars() == 1, "one-star threshold is applied")
	logic.moves = 9
	_check(logic.calculate_stars() == 0, "moves above the one-star threshold award no stars")


func _test_shipped_levels_are_solvable() -> void:
	print("TEST: all eight shipped levels have verified solutions")
	for index: int in range(1, 9):
		var path: String = "res://data/puzzles/circuit/circuit_%02d.tres" % index
		var level: CircuitLevel = load(path) as CircuitLevel
		_check(level != null, "level %02d resource loads" % index)
		if level == null:
			continue
		var solution: Dictionary[Vector2i, int] = CircuitLevelSolver.solve(level)
		_check(not solution.is_empty(), "level %02d authored solution is verified" % index)
		var logic: CircuitLogic = CircuitLogic.new()
		_check(logic.setup(level), "level %02d logic sets up" % index)
		_check(not logic.is_solved(), "level %02d starts scrambled" % index)
		var hint: Vector2i = logic.get_hint()
		_check(hint != CircuitLogic.INVALID_CELL, "level %02d has a usable hint" % index)
		_check(
			_minimum_solution_moves(level) <= level.three_star_moves,
			"level %02d three-star threshold covers its authored solution" % index
		)
		logic.set_solution_layout()
		_check(logic.is_solved(), "level %02d powers every required target" % index)
	var alternate_level: CircuitLevel = _linear_level(false)
	alternate_level.tiles[1].solution_rotation = 0
	var alternate_solution: Dictionary[Vector2i, int] = CircuitLevelSolver.solve(alternate_level)
	_check(not alternate_solution.is_empty(), "backtracking finds a solution beyond the authored hint orientation")
	var alternate_logic: CircuitLogic = CircuitLogic.new()
	_check(alternate_logic.setup(alternate_level), "alternate solution level sets up")
	for cell: Vector2i in alternate_solution:
		alternate_logic.rotations[cell] = alternate_solution[cell]
	_check(alternate_logic.is_solved(), "backtracking result powers its required target")


func _test_seeded_shuffle() -> void:
	print("TEST: deterministic shuffle from solved orientation")
	var level: CircuitLevel = load("res://data/puzzles/circuit/circuit_08.tres") as CircuitLevel
	var first: CircuitLogic = CircuitLogic.new()
	var second: CircuitLogic = CircuitLogic.new()
	_check(first.setup(level) and second.setup(level), "shuffle levels set up")
	first.shuffle_from_solution(3812)
	second.shuffle_from_solution(3812)
	_check(first.rotations == second.rotations, "same seed creates identical orientations")
	_check(not first.is_solved(), "shuffle produces a playable scrambled layout")


func _linear_level(solved: bool) -> CircuitLevel:
	var level: CircuitLevel = CircuitLevel.new()
	level.id = "test_linear"
	level.grid_columns = 3
	level.grid_rows = 1
	var straight_rotation: int = 1 if solved else 0
	level.tiles = [
		_make_tile(Vector2i(0, 0), CircuitTileDef.TileType.SOURCE, 1, 1),
		_make_tile(Vector2i(1, 0), CircuitTileDef.TileType.STRAIGHT, straight_rotation, 1),
		_make_tile(Vector2i(2, 0), CircuitTileDef.TileType.TARGET, 3, 3),
	]
	level.required_targets = [Vector2i(2, 0)]
	return level


func _minimum_solution_moves(level: CircuitLevel) -> int:
	var total: int = 0
	for tile: CircuitTileDef in level.tiles:
		if tile.locked or tile.type == CircuitTileDef.TileType.EMPTY or tile.type == CircuitTileDef.TileType.BLOCKER:
			continue
		var solution_mask: int = CircuitLogic.mask_for_type(tile.type, tile.solution_rotation)
		for steps: int in range(4):
			if CircuitLogic.mask_for_type(tile.type, tile.initial_rotation + steps) == solution_mask:
				total += steps
				break
	return total


func _make_tile(cell: Vector2i, type: CircuitTileDef.TileType, initial: int, solution: int) -> CircuitTileDef:
	var tile: CircuitTileDef = CircuitTileDef.new()
	tile.cell = cell
	tile.type = type
	tile.initial_rotation = initial
	tile.solution_rotation = solution
	return tile


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: %s" % description)
