## CircuitLogic — Pure logical state and algorithm engine for the Circuit Puzzle.
## Extends RefCounted; completely decoupled from Godot Nodes and UI.
class_name CircuitLogic
extends RefCounted


# Cardinal direction offsets and bitmasks:
# North: (0, -1), mask 1 (NORTH), opposite 4 (SOUTH)
# East:  (1,  0), mask 2 (EAST),  opposite 8 (WEST)
# South: (0,  1), mask 4 (SOUTH), opposite 1 (NORTH)
# West:  (-1, 0), mask 8 (WEST),  opposite 2 (EAST)
const DIRECTIONS: Array[Dictionary] = [
	{"offset": Vector2i(0, -1), "mask": CircuitTileDef.Direction.NORTH, "opposite": CircuitTileDef.Direction.SOUTH},
	{"offset": Vector2i(1, 0),  "mask": CircuitTileDef.Direction.EAST,  "opposite": CircuitTileDef.Direction.WEST},
	{"offset": Vector2i(0, 1),  "mask": CircuitTileDef.Direction.SOUTH, "opposite": CircuitTileDef.Direction.NORTH},
	{"offset": Vector2i(-1, 0), "mask": CircuitTileDef.Direction.WEST,  "opposite": CircuitTileDef.Direction.EAST},
]

## Active level definition reference.
var level: CircuitLevel

## Grid dimensions.
var columns: int = 0
var rows: int = 0

## Internal tile state map: cell (Vector2i) -> Dictionary with keys:
## "type": CircuitTileDef.CircuitTileType,
## "rotation": int (0..3),
## "locked": bool,
## "label_key": String,
## "solution_rotation": int
var _grid_state: Dictionary = {}

## Move counter tracking user rotations.
var moves: int = 0

## Number of hints used.
var hints_used: int = 0

## Last computed BFS traversal order: Array[Vector2i].
var last_bfs_order: Array[Vector2i] = []


## Initializes grid state from a CircuitLevel resource.
func load_level(p_level: CircuitLevel) -> void:
	assert(p_level != null, "CircuitLogic: CircuitLevel must not be null.")
	level = p_level
	columns = level.grid_columns
	rows = level.grid_rows
	moves = 0
	hints_used = 0
	_grid_state.clear()
	last_bfs_order.clear()

	for y: int in range(rows):
		for x: int in range(columns):
			var cell: Vector2i = Vector2i(x, y)
			var def: CircuitTileDef = level.get_tile_def(cell)
			if def != null:
				_grid_state[cell] = {
					"type": def.tile_type,
					"rotation": (def.rotation_index % 4 + 4) % 4,
					"locked": def.locked,
					"label_key": def.label_key,
					"solution_rotation": (def.solution_rotation % 4 + 4) % 4,
				}
			else:
				_grid_state[cell] = {
					"type": CircuitTileDef.CircuitTileType.EMPTY,
					"rotation": 0,
					"locked": true,
					"label_key": "",
					"solution_rotation": 0,
				}


## Attempts to rotate the tile at the given cell 90 degrees clockwise.
## Increments move counter only if the tile is rotatable and not locked.
func rotate_tile(cell: Vector2i) -> bool:
	if not _grid_state.has(cell):
		return false
	var state: Dictionary = _grid_state[cell] as Dictionary
	if state["locked"] as bool:
		return false
	var type: CircuitTileDef.CircuitTileType = state["type"] as CircuitTileDef.CircuitTileType
	if type == CircuitTileDef.CircuitTileType.EMPTY or type == CircuitTileDef.CircuitTileType.BLOCKER:
		return false

	var current_rot: int = state["rotation"] as int
	state["rotation"] = (current_rot + 1) % 4
	moves += 1
	return true


## Directly sets rotation without incrementing move counter (used by hint or solver).
func set_tile_rotation(cell: Vector2i, rot: int) -> void:
	if _grid_state.has(cell):
		var state: Dictionary = _grid_state[cell] as Dictionary
		state["rotation"] = (rot % 4 + 4) % 4


## Returns the current rotation index (0..3) of a tile.
func get_tile_rotation(cell: Vector2i) -> int:
	if _grid_state.has(cell):
		var state: Dictionary = _grid_state[cell] as Dictionary
		return state["rotation"] as int
	return 0


## Returns the tile type at cell.
func get_tile_type(cell: Vector2i) -> CircuitTileDef.CircuitTileType:
	if _grid_state.has(cell):
		var state: Dictionary = _grid_state[cell] as Dictionary
		return state["type"] as CircuitTileDef.CircuitTileType
	return CircuitTileDef.CircuitTileType.EMPTY


## Returns whether tile at cell is locked.
func is_tile_locked(cell: Vector2i) -> bool:
	if _grid_state.has(cell):
		var state: Dictionary = _grid_state[cell] as Dictionary
		return state["locked"] as bool
	return false


## Returns localized label key of tile at cell.
func get_tile_label_key(cell: Vector2i) -> String:
	if _grid_state.has(cell):
		var state: Dictionary = _grid_state[cell] as Dictionary
		return state["label_key"] as String
	return ""


## Returns the 4-bit connection mask for a tile based on its current type and rotation.
func get_tile_mask(cell: Vector2i) -> int:
	if not _grid_state.has(cell):
		return 0
	var state: Dictionary = _grid_state[cell] as Dictionary
	var type: CircuitTileDef.CircuitTileType = state["type"] as CircuitTileDef.CircuitTileType
	var rot: int = state["rotation"] as int
	var base_mask: int = CircuitTileDef.get_base_mask(type)
	return CircuitTileDef.rotate_mask(base_mask, rot)


## Computes powered status for every cell in the grid using BFS from all SOURCE nodes.
## An edge is traversed if and only if:
## (from_mask & dir_mask) != 0 AND (to_mask & opposite_mask) != 0.
## Returns a Dictionary[Vector2i, bool] indicating powered state for each cell.
func compute_powered() -> Dictionary:
	var powered: Dictionary = {}
	last_bfs_order.clear()

	# Initialize all cells as unpowered
	for y: int in range(rows):
		for x: int in range(columns):
			powered[Vector2i(x, y)] = false

	# Find all source nodes
	var queue: Array[Vector2i] = []
	for y: int in range(rows):
		for x: int in range(columns):
			var cell: Vector2i = Vector2i(x, y)
			if get_tile_type(cell) == CircuitTileDef.CircuitTileType.SOURCE:
				powered[cell] = true
				queue.append(cell)
				last_bfs_order.append(cell)

	# BFS traversal
	var head: int = 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		var current_mask: int = get_tile_mask(current)

		for dir_info: Dictionary in DIRECTIONS:
			var dir_mask: int = dir_info["mask"] as int
			if (current_mask & dir_mask) == 0:
				continue # Current tile does not open toward this direction

			var offset: Vector2i = dir_info["offset"] as Vector2i
			var neighbor: Vector2i = current + offset

			if neighbor.x < 0 or neighbor.x >= columns or neighbor.y < 0 or neighbor.y >= rows:
				continue # Out of bounds

			if powered.get(neighbor, false) as bool:
				continue # Already visited

			var neighbor_type: CircuitTileDef.CircuitTileType = get_tile_type(neighbor)
			if neighbor_type == CircuitTileDef.CircuitTileType.EMPTY or neighbor_type == CircuitTileDef.CircuitTileType.BLOCKER:
				continue

			var neighbor_mask: int = get_tile_mask(neighbor)
			var opp_mask: int = dir_info["opposite"] as int

			# Symmetrical edge check: neighbor must open toward current cell
			if (neighbor_mask & opp_mask) != 0:
				powered[neighbor] = true
				queue.append(neighbor)
				last_bfs_order.append(neighbor)

	return powered


## Checks if the level is solved.
## True when the count of powered TARGET tiles >= required_targets
## (or all targets if required_targets <= 0).
func is_solved() -> bool:
	var powered: Dictionary = compute_powered()
	var total_targets: int = 0
	var powered_targets: int = 0

	for y: int in range(rows):
		for x: int in range(columns):
			var cell: Vector2i = Vector2i(x, y)
			if get_tile_type(cell) == CircuitTileDef.CircuitTileType.TARGET:
				total_targets += 1
				if powered.get(cell, false) as bool:
					powered_targets += 1

	if total_targets == 0:
		return false

	var needed: int = level.required_targets if level.required_targets > 0 else total_targets
	return powered_targets >= needed


## Calculates star rating (1 to 3) based on moves and level star thresholds.
## If not solved, returns 0.
func calculate_stars() -> int:
	if not is_solved():
		return 0
	if level == null or level.star_thresholds.size() < 3:
		# Fallback to par_moves if thresholds not provided
		var par: int = level.par_moves if level != null else 10
		if moves <= par:
			return 3
		elif moves <= par + 4:
			return 2
		else:
			return 1

	if moves <= level.star_thresholds[0]:
		return 3
	elif moves <= level.star_thresholds[1]:
		return 2
	else:
		return 1


## Returns a cell that is currently wrongly oriented relative to the stored solution.
## Excludes locked tiles, blockers, empty tiles, and tiles whose mask is rotationally symmetric.
## Returns Vector2i(-1, -1) if no hint is available or all are correctly rotated.
func get_hint() -> Vector2i:
	for y: int in range(rows):
		for x: int in range(columns):
			var cell: Vector2i = Vector2i(x, y)
			var state: Dictionary = _grid_state.get(cell, {}) as Dictionary
			if state.is_empty():
				continue
			if state["locked"] as bool:
				continue
			var type: CircuitTileDef.CircuitTileType = state["type"] as CircuitTileDef.CircuitTileType
			if type == CircuitTileDef.CircuitTileType.EMPTY or type == CircuitTileDef.CircuitTileType.BLOCKER:
				continue

			var cur_rot: int = state["rotation"] as int
			var sol_rot: int = state["solution_rotation"] as int

			# Check if current mask differs from solution mask
			var base_mask: int = CircuitTileDef.get_base_mask(type)
			var cur_mask: int = CircuitTileDef.rotate_mask(base_mask, cur_rot)
			var sol_mask: int = CircuitTileDef.rotate_mask(base_mask, sol_rot)

			if cur_mask != sol_mask:
				return cell

	return Vector2i(-1, -1)
