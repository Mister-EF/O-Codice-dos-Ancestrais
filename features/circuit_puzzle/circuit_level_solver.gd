## Backtracking orientation solver used by tests and content tools.
class_name CircuitLevelSolver
extends RefCounted


static func solve(level: CircuitLevel) -> Dictionary[Vector2i, int]:
	var solution: Dictionary[Vector2i, int] = {}
	var logic: CircuitLogic = CircuitLogic.new()
	if not logic.setup(level):
		return solution
	var cells: Array[Vector2i] = []
	var options: Dictionary[Vector2i, PackedInt32Array] = {}
	for tile: CircuitTileDef in level.tiles:
		if tile.locked and CircuitLogic.mask_for_type(tile.type, tile.initial_rotation) != CircuitLogic.mask_for_type(tile.type, tile.solution_rotation):
			push_error("CircuitLevelSolver: locked tile %s has no valid authored orientation." % str(tile.cell))
			return solution
		cells.append(tile.cell)
		options[tile.cell] = _rotation_options(tile)
	var working: Dictionary[Vector2i, int] = {}
	if not _search(0, cells, options, working, logic):
		push_error("CircuitLevelSolver: no orientation powers every required target in '%s'." % level.id)
		return solution
	for cell: Vector2i in cells:
		solution[cell] = working[cell]
	return solution


static func _rotation_options(tile: CircuitTileDef) -> PackedInt32Array:
	var options: PackedInt32Array = PackedInt32Array()
	if tile.locked or tile.type == CircuitTileDef.TileType.EMPTY or tile.type == CircuitTileDef.TileType.BLOCKER:
		options.append(posmod(tile.initial_rotation, 4))
		return options
	var seen_masks: Dictionary[int, bool] = {}
	var preferred: int = posmod(tile.solution_rotation, 4)
	options.append(preferred)
	seen_masks[CircuitLogic.mask_for_type(tile.type, preferred)] = true
	for rotation: int in range(4):
		var mask: int = CircuitLogic.mask_for_type(tile.type, rotation)
		if not seen_masks.has(mask):
			options.append(rotation)
			seen_masks[mask] = true
	return options


static func _search(
	index: int,
	cells: Array[Vector2i],
	options: Dictionary[Vector2i, PackedInt32Array],
	working: Dictionary[Vector2i, int],
	logic: CircuitLogic
) -> bool:
	if index >= cells.size():
		return logic.is_solved()
	var cell: Vector2i = cells[index]
	for rotation: int in options[cell]:
		working[cell] = rotation
		logic.rotations[cell] = rotation
		if _search(index + 1, cells, options, working, logic):
			return true
	working.erase(cell)
	return false
