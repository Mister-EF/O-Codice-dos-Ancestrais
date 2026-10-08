## One authored cell in a circuit puzzle.
class_name CircuitTileDef
extends Resource

enum TileType { EMPTY, STRAIGHT, CORNER, T_JUNCTION, CROSS, SOURCE, TARGET, BLOCKER }

@export var cell: Vector2i = Vector2i.ZERO
@export var type: TileType = TileType.EMPTY
@export_range(0, 3) var initial_rotation: int = 0
@export var locked: bool = false
@export var label_key: String = ""
@export_range(0, 3) var solution_rotation: int = 0
