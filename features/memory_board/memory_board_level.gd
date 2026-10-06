## Data-driven configuration for a memory-board puzzle.
class_name MemoryBoardLevel
extends Resource

enum PairMode { NAME_TO_DEFINITION, NAME_TO_ICON, MIXED }

@export var id: String = ""
@export var title_key: String = ""
@export var intro_key: String = ""
@export var grid_columns: int = 2
@export var grid_rows: int = 3
@export var concept_ids: Array[StringName] = []
@export var pair_mode: PairMode = PairMode.NAME_TO_DEFINITION
@export var max_moves: int = 0
@export var time_limit_seconds: float = 0.0
@export var three_star_moves: int = 0
@export var two_star_moves: int = 0
@export var one_star_moves: int = 0
