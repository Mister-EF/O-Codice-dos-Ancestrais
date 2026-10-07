## CircuitTileDef — Data resource representing a single tile in a circuit puzzle grid.
## Pure data resource; no node dependencies.
class_name CircuitTileDef
extends Resource


## Connection mask bitflags for cardinal directions.
## NORTH = 1 (1 << 0), EAST = 2 (1 << 1), SOUTH = 4 (1 << 2), WEST = 8 (1 << 3).
enum Direction {
	NORTH = 1,
	EAST = 2,
	SOUTH = 4,
	WEST = 8,
}

## Tile types available in the circuit puzzle.
enum CircuitTileType {
	EMPTY,
	STRAIGHT,
	CORNER,
	T_JUNCTION,
	CROSS,
	SOURCE,
	TARGET,
	BLOCKER,
}

## Type of this tile.
@export var tile_type: CircuitTileType = CircuitTileType.EMPTY

## Initial rotation state (0 = 0 deg, 1 = 90 deg, 2 = 180 deg, 3 = 270 deg clockwise).
@export var rotation_index: int = 0

## If true, this tile cannot be rotated by the player.
@export var locked: bool = false

## Optional localization key for concept label (e.g. "concept.flow.parse").
@export var label_key: String = ""

## Solution rotation index (0..3) used by validator, generator and hint system.
@export var solution_rotation: int = 0


## Helper to get base connection bitmask (at rotation_index 0) for each tile type.
static func get_base_mask(type: CircuitTileType) -> int:
	match type:
		CircuitTileType.STRAIGHT:
			# North and South
			return Direction.NORTH | Direction.SOUTH
		CircuitTileType.CORNER:
			# North and East
			return Direction.NORTH | Direction.EAST
		CircuitTileType.T_JUNCTION:
			# North, East and South
			return Direction.NORTH | Direction.EAST | Direction.SOUTH
		CircuitTileType.CROSS:
			# All 4 directions
			return Direction.NORTH | Direction.EAST | Direction.SOUTH | Direction.WEST
		CircuitTileType.SOURCE:
			# Default points North (can be rotated or locked)
			return Direction.NORTH
		CircuitTileType.TARGET:
			# Default opens from South (connecting northwards) or North. Standard: NORTH
			return Direction.NORTH
		_:
			return 0


## Computes the 4-bit rotated mask given base mask and rotation steps (0..3 clockwise).
## Bit rotation: bit 0(N)->bit 1(E)->bit 2(S)->bit 3(W)->bit 0(N).
static func rotate_mask(mask: int, steps: int) -> int:
	var s: int = (steps % 4 + 4) % 4
	var res: int = 0
	for bit: int in range(4):
		if (mask & (1 << bit)) != 0:
			var new_bit: int = (bit + s) % 4
			res |= (1 << new_bit)
	return res
