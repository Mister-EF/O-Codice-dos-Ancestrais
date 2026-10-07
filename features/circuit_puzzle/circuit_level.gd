## CircuitLevel — Resource describing a complete circuit puzzle level layout and rules.
## Pure data resource; no node dependencies.
class_name CircuitLevel
extends Resource


## Unique puzzle identifier, e.g. "circuit_01".
@export var id: String = ""

## Translation key for level title.
@export var title_key: String = ""

## Translation key for educational intro dialog / explanation.
@export var intro_key: String = ""

## Number of columns in the grid.
@export var grid_columns: int = 3

## Number of rows in the grid.
@export var grid_rows: int = 3

## Flat array of tile definitions of size (grid_columns * grid_rows), indexed by row * grid_columns + col.
@export var tiles: Array[CircuitTileDef] = []

## Minimum number of target nodes that must be powered to win (0 = all targets).
@export var required_targets: int = 1

## Target move count for optimal solution (par).
@export var par_moves: int = 10

## Move count thresholds for stars [3_stars_max_moves, 2_stars_max_moves, 1_star_max_moves].
## e.g. moves <= star_thresholds[0] -> 3 stars, moves <= star_thresholds[1] -> 2 stars, else 1 star.
@export var star_thresholds: Array[int] = [10, 15, 25]

## Optional time limit in seconds (0.0 or negative means untimed).
@export var time_limit_seconds: float = 0.0


## Helper to get tile definition at a 2D coordinate.
func get_tile_def(cell: Vector2i) -> CircuitTileDef:
	if cell.x < 0 or cell.x >= grid_columns or cell.y < 0 or cell.y >= grid_rows:
		return null
	var idx: int = cell.y * grid_columns + cell.x
	if idx >= 0 and idx < tiles.size():
		return tiles[idx]
	return null
