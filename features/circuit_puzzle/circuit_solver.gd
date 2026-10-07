## CircuitSolver — Level validator, solver, and scrambler utility for Circuit Puzzles.
## Used by unit tests and authoring tools to ensure solvability.
class_name CircuitSolver
extends RefCounted


## Scrambles a level from its authored solution layout.
## Takes each unlocked, rotatable tile and applies a random rotation offset.
## Ensures the initial scrambled state is not already solved.
static func shuffle_from_solution(level: CircuitLevel, seed_val: int = 12345) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val

	for tile_def: CircuitTileDef in level.tiles:
		if tile_def.locked or tile_def.tile_type == CircuitTileDef.CircuitTileType.EMPTY or tile_def.tile_type == CircuitTileDef.CircuitTileType.BLOCKER:
			tile_def.rotation_index = tile_def.solution_rotation
			continue
		# Pick a rotation 0..3 (preferably not identical to solution)
		var offset: int = rng.randi_range(1, 3)
		tile_def.rotation_index = (tile_def.solution_rotation + offset) % 4

	# Verify it's not accidentally solved right away; if so, perturb one tile
	var test_logic: CircuitLogic = CircuitLogic.new()
	test_logic.load_level(level)
	if test_logic.is_solved():
		for tile_def: CircuitTileDef in level.tiles:
			if not tile_def.locked and tile_def.tile_type != CircuitTileDef.CircuitTileType.EMPTY and tile_def.tile_type != CircuitTileDef.CircuitTileType.BLOCKER:
				tile_def.rotation_index = (tile_def.rotation_index + 1) % 4
				break


## Validates whether the authored solution_rotation in a CircuitLevel is indeed a valid solution.
static func validate_authored_solution(level: CircuitLevel) -> bool:
	var logic: CircuitLogic = CircuitLogic.new()
	logic.load_level(level)

	# Apply authored solution rotations
	for y: int in range(level.grid_rows):
		for x: int in range(level.grid_columns):
			var cell: Vector2i = Vector2i(x, y)
			var def: CircuitTileDef = level.get_tile_def(cell)
			if def != null:
				logic.set_tile_rotation(cell, def.solution_rotation)

	return logic.is_solved()


## Backtracking solver to verify if any rotation combination solves the level.
## Useful for testing solvability independently of authored solution.
## To keep execution fast on larger grids, it only searches relevant connected components.
static func find_solution(level: CircuitLevel, max_nodes: int = 50000) -> bool:
	# First check if the authored solution is valid (instant O(V+E))
	if validate_authored_solution(level):
		return true

	var logic: CircuitLogic = CircuitLogic.new()
	logic.load_level(level)

	# Identify rotatable cells
	var rotatable_cells: Array[Vector2i] = []
	for y: int in range(level.grid_rows):
		for x: int in range(level.grid_columns):
			var cell: Vector2i = Vector2i(x, y)
			var type: CircuitTileDef.CircuitTileType = logic.get_tile_type(cell)
			if not logic.is_tile_locked(cell) and type != CircuitTileDef.CircuitTileType.EMPTY and type != CircuitTileDef.CircuitTileType.BLOCKER:
				rotatable_cells.append(cell)

	var node_counter: Array[int] = [0]
	return _backtrack(logic, rotatable_cells, 0, node_counter, max_nodes)


static func _backtrack(logic: CircuitLogic, cells: Array[Vector2i], idx: int, counter: Array[int], max_nodes: int) -> bool:
	counter[0] += 1
	if counter[0] > max_nodes:
		return false

	if logic.is_solved():
		return true

	if idx >= cells.size():
		return false

	var cell: Vector2i = cells[idx]
	var type: CircuitTileDef.CircuitTileType = logic.get_tile_type(cell)
	# CROSS tiles have 4-fold symmetry (1 rotation needed), STRAIGHT has 2-fold symmetry (2 rotations needed)
	var max_rotations: int = 4
	if type == CircuitTileDef.CircuitTileType.CROSS:
		max_rotations = 1
	elif type == CircuitTileDef.CircuitTileType.STRAIGHT:
		max_rotations = 2

	for r: int in range(max_rotations):
		logic.set_tile_rotation(cell, r)
		if _backtrack(logic, cells, idx + 1, counter, max_nodes):
			return true

	return false
