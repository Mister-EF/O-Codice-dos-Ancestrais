## Data-driven circuit puzzle configuration.
class_name CircuitLevel
extends Resource

@export var id: String = ""
@export var title_key: String = ""
@export var intro_key: String = ""
@export var grid_columns: int = 3
@export var grid_rows: int = 3
@export var tiles: Array[CircuitTileDef] = []
@export var required_targets: Array[Vector2i] = []
@export var par_moves: int = 0
@export var three_star_moves: int = 0
@export var two_star_moves: int = 0
@export var one_star_moves: int = 0
@export var time_limit_seconds: float = 0.0
