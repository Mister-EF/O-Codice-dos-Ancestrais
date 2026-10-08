## Pure circuit puzzle rules; independent from the scene tree and autoloads.
class_name CircuitLogic
extends RefCounted

const INVALID_CELL: Vector2i = Vector2i(-1, -1)
const NORTH: int = 1
const EAST: int = 2
const SOUTH: int = 4
const WEST: int = 8
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var level: CircuitLevel
var rotations: Dictionary[Vector2i, int] = {}
var tiles: Dictionary[Vector2i, CircuitTileDef] = {}
var moves: int = 0
var hints_used: int = 0
var hint_move_cost: float = 1.0
var failed: bool = false


func setup(p_level: CircuitLevel, faction_bonus: FactionData = null) -> bool:
	if p_level == null:
		push_error("CircuitLogic: level must not be null.")
		return false
	if p_level.grid_columns < 1 or p_level.grid_rows < 1:
		push_error("CircuitLogic: grid dimensions must be positive.")
		return false
	if (
		p_level.par_moves < 0
		or p_level.time_limit_seconds < 0.0
		or p_level.three_star_moves < 0
		or p_level.two_star_moves < 0
		or p_level.one_star_moves < 0
	):
		push_error("CircuitLogic: par and time limit cannot be negative.")
		return false
	if p_level.three_star_moves > 0 and p_level.two_star_moves > 0 and p_level.three_star_moves > p_level.two_star_moves:
		push_error("CircuitLogic: three-star threshold must not exceed the two-star threshold.")
		return false
	if p_level.two_star_moves > 0 and p_level.one_star_moves > 0 and p_level.two_star_moves > p_level.one_star_moves:
		push_error("CircuitLogic: two-star threshold must not exceed the one-star threshold.")
		return false

	var new_tiles: Dictionary[Vector2i, CircuitTileDef] = {}
	var new_rotations: Dictionary[Vector2i, int] = {}
	var source_count: int = 0
	for tile: CircuitTileDef in p_level.tiles:
		if tile == null:
			push_error("CircuitLogic: tile definitions cannot be null.")
			return false
		if tile.cell.x < 0 or tile.cell.y < 0 or tile.cell.x >= p_level.grid_columns or tile.cell.y >= p_level.grid_rows:
			push_error("CircuitLogic: tile cell %s is outside the grid." % str(tile.cell))
			return false
		if new_tiles.has(tile.cell):
			push_error("CircuitLogic: duplicate tile cell %s." % str(tile.cell))
			return false
		new_tiles[tile.cell] = tile
		new_rotations[tile.cell] = posmod(tile.initial_rotation, 4)
		if tile.type == CircuitTileDef.TileType.SOURCE:
			source_count += 1
	if source_count != 1:
		push_error("CircuitLogic: a level must contain exactly one source.")
		return false
	if p_level.required_targets.is_empty():
		push_error("CircuitLogic: a level must require at least one target.")
		return false
	var seen_targets: Dictionary[Vector2i, bool] = {}
	for target_cell: Vector2i in p_level.required_targets:
		if seen_targets.has(target_cell):
			push_error("CircuitLogic: required target %s is listed more than once." % str(target_cell))
			return false
		seen_targets[target_cell] = true
		if not new_tiles.has(target_cell) or new_tiles[target_cell].type != CircuitTileDef.TileType.TARGET:
			push_error("CircuitLogic: required target %s is not a target tile." % str(target_cell))
			return false
	level = p_level
	tiles = new_tiles
	rotations = new_rotations
	moves = 0
	hints_used = 0
	failed = false
	hint_move_cost = 1.0
	if faction_bonus != null:
		hint_move_cost = 1.0 - float(clampi(faction_bonus.hint_discount, 0, 100)) / 100.0
	return true


func rotate_tile(cell: Vector2i) -> void:
	if not tiles.has(cell):
		return
	var tile: CircuitTileDef = tiles[cell]
	if tile.locked or tile.type == CircuitTileDef.TileType.EMPTY or tile.type == CircuitTileDef.TileType.BLOCKER:
		return
	rotations[cell] = posmod(rotations[cell] + 1, 4)
	moves += 1


func compute_powered() -> Dictionary[Vector2i, bool]:
	var powered: Dictionary[Vector2i, bool] = {}
	var source: Vector2i = INVALID_CELL
	for cell: Vector2i in tiles:
		if tiles[cell].type == CircuitTileDef.TileType.SOURCE:
			source = cell
			break
	if source == INVALID_CELL:
		return powered

	var queue: Array[Vector2i] = [source]
	powered[source] = true
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var current_mask: int = _mask_for_cell(current)
		for direction: Vector2i in DIRECTIONS:
			var neighbor: Vector2i = current + direction
			if powered.has(neighbor) or not tiles.has(neighbor):
				continue
			var edge: int = _edge_for_direction(direction)
			var neighbor_mask: int = _mask_for_cell(neighbor)
			if (current_mask & edge) != 0 and (neighbor_mask & _opposite(edge)) != 0:
				powered[neighbor] = true
				queue.append(neighbor)
	return powered


func get_powered_order() -> Array[Vector2i]:
	var order: Array[Vector2i] = []
	var powered: Dictionary[Vector2i, bool] = compute_powered()
	var source: Vector2i = INVALID_CELL
	for cell: Vector2i in tiles:
		if tiles[cell].type == CircuitTileDef.TileType.SOURCE:
			source = cell
			break
	if source == INVALID_CELL:
		return order
	var queue: Array[Vector2i] = [source]
	var visited: Dictionary[Vector2i, bool] = {source: true}
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		order.append(current)
		for direction: Vector2i in DIRECTIONS:
			var neighbor: Vector2i = current + direction
			if not powered.has(neighbor) or visited.has(neighbor):
				continue
			var edge: int = _edge_for_direction(direction)
			if (_mask_for_cell(current) & edge) != 0 and (_mask_for_cell(neighbor) & _opposite(edge)) != 0:
				visited[neighbor] = true
				queue.append(neighbor)
	return order


func is_solved() -> bool:
	if failed or level == null:
		return false
	var powered: Dictionary[Vector2i, bool] = compute_powered()
	for target: Vector2i in level.required_targets:
		if not powered.has(target):
			return false
	return true


func get_hint() -> Vector2i:
	if level == null or is_solved():
		return INVALID_CELL
	for tile: CircuitTileDef in level.tiles:
		if tile.locked or tile.type == CircuitTileDef.TileType.EMPTY or tile.type == CircuitTileDef.TileType.BLOCKER:
			continue
		var current_mask: int = _mask_for_cell(tile.cell)
		var solution_mask: int = mask_for_type(tile.type, tile.solution_rotation)
		if current_mask != solution_mask:
			return tile.cell
	return INVALID_CELL


func register_hint() -> bool:
	if get_hint() == INVALID_CELL:
		return false
	hints_used += 1
	return true


func calculate_stars() -> int:
	if not is_solved():
		return 0
	var scored_moves: float = float(moves) + float(hints_used) * hint_move_cost
	if level.three_star_moves > 0 and scored_moves <= float(level.three_star_moves):
		return 3
	if level.two_star_moves > 0 and scored_moves <= float(level.two_star_moves):
		return 2
	if level.one_star_moves == 0 or scored_moves <= float(level.one_star_moves):
		return 1
	return 0


func set_solution_layout() -> void:
	if level == null:
		return
	for tile: CircuitTileDef in level.tiles:
		rotations[tile.cell] = posmod(tile.solution_rotation, 4)
	moves = 0
	hints_used = 0
	failed = false


func shuffle_from_solution(seed: int) -> void:
	if level == null:
		push_error("CircuitLogic: setup a level before shuffling.")
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	for tile: CircuitTileDef in level.tiles:
		var solution: int = posmod(tile.solution_rotation, 4)
		if tile.locked or tile.type == CircuitTileDef.TileType.EMPTY or tile.type == CircuitTileDef.TileType.BLOCKER:
			rotations[tile.cell] = solution
			continue
		var choices: Array[int] = []
		for offset: int in range(1, 4):
			var candidate: int = posmod(solution + offset, 4)
			if mask_for_type(tile.type, candidate) != mask_for_type(tile.type, solution):
				choices.append(candidate)
		rotations[tile.cell] = choices[rng.randi_range(0, choices.size() - 1)] if not choices.is_empty() else solution
	moves = 0
	hints_used = 0
	failed = false
	if is_solved():
		var changed_orientation: bool = false
		for tile: CircuitTileDef in level.tiles:
			if tile.locked or tile.type == CircuitTileDef.TileType.EMPTY or tile.type == CircuitTileDef.TileType.BLOCKER:
				continue
			for offset: int in range(1, 4):
				var candidate: int = posmod(rotations[tile.cell] + offset, 4)
				if mask_for_type(tile.type, candidate) != _mask_for_cell(tile.cell):
					rotations[tile.cell] = candidate
					changed_orientation = true
					break
			if changed_orientation:
				break
		if not changed_orientation or is_solved():
			push_error("CircuitLogic: could not produce an unsolved shuffle for level '%s'." % level.id)


func _mask_for_cell(cell: Vector2i) -> int:
	if not tiles.has(cell):
		return 0
	return mask_for_type(tiles[cell].type, int(rotations.get(cell, 0)))


static func mask_for_type(type: CircuitTileDef.TileType, rotation: int) -> int:
	var mask: int = 0
	match type:
		CircuitTileDef.TileType.STRAIGHT:
			mask = NORTH | SOUTH
		CircuitTileDef.TileType.CORNER:
			mask = NORTH | EAST
		CircuitTileDef.TileType.T_JUNCTION:
			mask = NORTH | EAST | WEST
		CircuitTileDef.TileType.CROSS:
			mask = NORTH | EAST | SOUTH | WEST
		CircuitTileDef.TileType.SOURCE, CircuitTileDef.TileType.TARGET:
			mask = NORTH
		_:
			return 0
	for _step: int in range(posmod(rotation, 4)):
		mask = ((mask << 1) & 15) | ((mask >> 3) & 1)
	return mask


static func _edge_for_direction(direction: Vector2i) -> int:
	if direction == Vector2i.UP:
		return NORTH
	if direction == Vector2i.RIGHT:
		return EAST
	if direction == Vector2i.DOWN:
		return SOUTH
	return WEST


static func _opposite(edge: int) -> int:
	return ((edge << 2) & 15) | (edge >> 2)
