## Authored Boolean-network puzzle, including graph, interaction mode, and scoring goals.
class_name RuneLevel
extends Resource

enum PuzzleMode { SET_INPUTS, PLACE_GATES, TRUTH_TABLE, MIXED }

@export var id: String = ""
@export var title_key: String = ""
@export var intro_key: String = ""
@export var clue_1_key: String = ""
@export var clue_2_key: String = ""
@export var clue_3_key: String = ""
@export var mode: PuzzleMode = PuzzleMode.SET_INPUTS
@export var nodes: Array[RuneNodeDef] = []
@export var tray: Array[RuneNodeDef.RuneGateType] = []
@export var target_value: bool = true
@export var output_node_id: StringName = &"output"
@export var truth_table_input_ids: Array[StringName] = []
@export var truth_table_missing_rows: Array[int] = []
@export var par_moves: int = 0
@export var three_star_moves: int = 0
@export var two_star_moves: int = 0
@export var one_star_moves: int = 0
