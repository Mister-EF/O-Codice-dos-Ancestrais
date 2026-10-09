## Resource definition for a Memory Board puzzle level.
class_name MemoryBoardLevel
extends Resource

enum PairMode {
	NAME_TO_DEFINITION,
	NAME_TO_ICON,
	MIXED
}

@export var id: String = ""
@export var title_key: String = ""
@export var intro_key: String = ""
@export var grid_columns: int = 4
@export var grid_rows: int = 3
@export var concept_ids: Array[StringName] = []
@export var pair_mode: PairMode = PairMode.NAME_TO_DEFINITION
@export var max_moves: int = 0 # 0 = unlimited
@export var time_limit_seconds: float = 0.0 # 0.0 = unlimited
@export var star_thresholds: Array[int] = [10, 15, 20] # [3 stars, 2 stars, 1 star] (max allowed moves for rating)
