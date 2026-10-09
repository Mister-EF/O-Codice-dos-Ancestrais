## Data-driven definition of a rune logic puzzle.
class_name RuneLevel
extends Resource


## Supported interactive modes.
enum Mode { SET_INPUTS, PLACE_GATES, TRUTH_TABLE }

## Puzzle identifier, following runes_01 through runes_10.
@export var id: String = ""
## Translation key for the level title.
@export var title_key: String = ""
## Translation key for the level introduction.
@export var intro_key: String = ""
## Level interaction mode.
@export var mode: Mode = Mode.SET_INPUTS
## Nodes forming the expression graph.
@export var nodes: Array[RuneNodeData] = []
## Gates available to place in EMPTY_SLOT nodes (RuneGateType.Type enum values).
@export var tray: Array[int] = []
## Required final output value.
@export var target_value: bool = true
## Input node IDs used to generate truth-table rows.
@export var truth_table_input_ids: Array[StringName] = []
## Output cells: -1 is blank, 0 is FALSE, and 1 is TRUE.
@export var truth_table_outputs: Array[int] = []
## Move count for a three-star solution.
@export var par_moves: int = 1
## Maximum moves for three stars.
@export var three_star_moves: int = 1
## Maximum moves for two stars.
@export var two_star_moves: int = 3
## Progressive localized clue keys.
@export var clue_1_key: String = ""
@export var clue_2_key: String = ""
@export var clue_3_key: String = ""


## Validates identifiers, graph links, mode-specific data, and star thresholds.
func validate_level() -> bool:
	if id.is_empty() or nodes.is_empty() or par_moves < 1:
		return false
	if three_star_moves < 1 or two_star_moves < three_star_moves:
		return false
	var ids: Dictionary[StringName, bool] = {}
	for node_data: RuneNodeData in nodes:
		if node_data == null or node_data.id == &"" or ids.has(node_data.id):
			return false
		ids[node_data.id] = true
	for node_data: RuneNodeData in nodes:
		for input_id: StringName in node_data.input_ids:
			if not ids.has(input_id):
				return false
	if mode == Mode.PLACE_GATES:
		var empty_count: int = 0
		for node_data: RuneNodeData in nodes:
			if node_data.gate_type == RuneGateType.Type.EMPTY_SLOT:
				empty_count += 1
		if empty_count != tray.size():
			return false
	if mode == Mode.TRUTH_TABLE:
		if truth_table_outputs.size() != (1 << truth_table_input_ids.size()):
			return false
		for input_id: StringName in truth_table_input_ids:
			if not ids.has(input_id):
				return false
	return true