## Truth-table generation and answer validation for rune expressions.
class_name TruthTableLogic
extends RefCounted

var level: RuneLevel
var input_ids: Array[StringName] = []
var rows: Array[Dictionary] = []
var answers: Dictionary[int, bool] = {}
var answered_rows: Dictionary[int, bool] = {}
var moves: int = 0
var hints_used: int = 0
var hint_cost: float = 1.0
var has_error: bool = false
var last_error: String = ""


func setup(p_level: RuneLevel, faction_bonus: FactionData = null) -> bool:
	if p_level == null or p_level.mode != RuneLevel.PuzzleMode.TRUTH_TABLE:
		return _fail("TruthTableLogic: setup requires a TRUTH_TABLE level.")
	if p_level.truth_table_input_ids.is_empty() or p_level.truth_table_input_ids.size() > 4:
		return _fail("TruthTableLogic: truth tables require one to four inputs.")
	level = p_level
	input_ids = p_level.truth_table_input_ids.duplicate()
	rows.clear()
	answers.clear()
	answered_rows.clear()
	moves = 0
	hints_used = 0
	hint_cost = 1.0
	if faction_bonus != null:
		hint_cost = 1.0 - float(clampi(faction_bonus.hint_discount, 0, 100)) / 100.0
	has_error = false
	last_error = ""

	var expression: RuneLogic = RuneLogic.new()
	if not expression.setup(level):
		return _fail(expression.last_error)
	var seen_inputs: Dictionary[StringName, bool] = {}
	for input_id: StringName in input_ids:
		if seen_inputs.has(input_id):
			return _fail("TruthTableLogic: input '%s' is listed more than once." % String(input_id))
		if not expression.nodes.has(input_id) or expression.nodes[input_id].gate_type != RuneNodeDef.RuneGateType.INPUT:
			return _fail("TruthTableLogic: '%s' is not an input node." % String(input_id))
		seen_inputs[input_id] = true
	var seen_missing_rows: Dictionary[int, bool] = {}
	for row_index: int in p_level.truth_table_missing_rows:
		if seen_missing_rows.has(row_index):
			return _fail("TruthTableLogic: row %d is marked missing more than once." % row_index)
		seen_missing_rows[row_index] = true
	var input_count: int = input_ids.size()
	for row_index: int in range(1 << input_count):
		var overrides: Dictionary[StringName, bool] = {}
		var row_inputs: Array[bool] = []
		for bit_index: int in range(input_count):
			var value: bool = ((row_index >> (input_count - bit_index - 1)) & 1) == 1
			overrides[input_ids[bit_index]] = value
			row_inputs.append(value)
		var values: Dictionary[StringName, bool] = expression.evaluate(overrides)
		if expression.has_error or not values.has(level.output_node_id):
			return _fail(expression.last_error)
		var expected: bool = values[level.output_node_id]
		var row: Dictionary = {"inputs": row_inputs, "expected": expected}
		rows.append(row)
		answers[row_index] = expected
		if not p_level.truth_table_missing_rows.has(row_index):
			answered_rows[row_index] = true
		else:
			answers[row_index] = false
	for missing_index: int in p_level.truth_table_missing_rows:
		if missing_index < 0 or missing_index >= rows.size():
			return _fail("TruthTableLogic: missing row %d is outside the generated table." % missing_index)
	return true


func toggle_answer(row_index: int) -> bool:
	if level == null or not level.truth_table_missing_rows.has(row_index):
		return false
	answers[row_index] = not bool(answers.get(row_index, false))
	answered_rows[row_index] = true
	moves += 1
	return true


func set_answer(row_index: int, value: bool) -> bool:
	if level == null or not level.truth_table_missing_rows.has(row_index):
		return false
	if answered_rows.has(row_index) and bool(answers[row_index]) == value:
		return false
	if not answered_rows.has(row_index) or bool(answers[row_index]) != value:
		moves += 1
	answers[row_index] = value
	answered_rows[row_index] = true
	return true


func is_solved() -> bool:
	if level == null or has_error:
		return false
	for row_index: int in level.truth_table_missing_rows:
		if not answered_rows.has(row_index) or bool(answers[row_index]) != bool(rows[row_index]["expected"]):
			return false
	return true


func get_hint() -> int:
	if level == null or is_solved():
		return -1
	for row_index: int in level.truth_table_missing_rows:
		if not answered_rows.has(row_index) or bool(answers[row_index]) != bool(rows[row_index]["expected"]):
			return row_index
	return -1


func register_hint() -> bool:
	if get_hint() < 0:
		return false
	hints_used += 1
	return true


func calculate_stars() -> int:
	if not is_solved():
		return 0
	var scored_moves: float = float(moves) + float(hints_used) * hint_cost
	if level.three_star_moves > 0 and scored_moves <= float(level.three_star_moves):
		return 3
	if level.two_star_moves > 0 and scored_moves <= float(level.two_star_moves):
		return 2
	if level.one_star_moves == 0 or scored_moves <= float(level.one_star_moves):
		return 1
	return 0


func _fail(message: String) -> bool:
	has_error = true
	last_error = message
	push_error(message)
	return false
