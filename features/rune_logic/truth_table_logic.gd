## Pure truth-table generator and answer validator for rune expressions.
class_name TruthTableLogic
extends RefCounted


var level: RuneLevel
var moves: int = 0
var _expected: Array[int] = []
var _answers: Array[int] = []


## Creates table rows for the expression graph stored in a level.
func _init(source_level: RuneLevel = null) -> void:
	if source_level != null:
		configure(source_level)


## Resets the table answers from the level's blank-cell definition.
func configure(source_level: RuneLevel) -> void:
	assert(source_level != null and source_level.mode == RuneLevel.Mode.TRUTH_TABLE, "Invalid truth table level")
	level = source_level
	moves = 0
	_expected.clear()
	_answers.clear()
	for output: int in source_level.truth_table_outputs:
		_expected.append(output)
		_answers.append(output)


## Returns generated rows as input assignments with nullable output answers.
func generate_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var row_count: int = 1 << level.truth_table_input_ids.size()
	for row_index: int in range(row_count):
		var inputs: Dictionary[StringName, bool] = {}
		for column: int in range(level.truth_table_input_ids.size()):
			var bit_index: int = level.truth_table_input_ids.size() - column - 1
			inputs[level.truth_table_input_ids[column]] = (row_index & (1 << bit_index)) != 0
		var expression: RuneLogic = RuneLogic.new(level)
		for input_id: StringName in level.truth_table_input_ids:
			expression._input_values[input_id] = inputs[input_id]
		var values: Dictionary[StringName, bool] = expression.evaluate()
		var output_node: RuneNodeData = expression._find_output()
		var output_value: bool = output_node != null and values.get(output_node.id, false)
		rows.append({"inputs": inputs, "output": output_value, "answer": _answers[row_index]})
	return rows


## Changes a blank output cell to TRUE (1) or FALSE (0).
func set_answer(row_index: int, value: bool) -> bool:
	if row_index < 0 or row_index >= _answers.size() or _expected[row_index] != -1:
		return false
	_answers[row_index] = 1 if value else 0
	moves += 1
	return true


## Cycles a blank cell from unanswered to TRUE to FALSE and back to unanswered.
func cycle_answer(row_index: int) -> bool:
	if row_index < 0 or row_index >= _answers.size() or _expected[row_index] != -1:
		return false
	match _answers[row_index]:
		-1:
			_answers[row_index] = 1
		0:
			_answers[row_index] = -1
		_:
			_answers[row_index] = 0
	moves += 1
	return true


## Returns true when every missing cell matches the generated expression output.
func validate_answers() -> bool:
	var rows: Array[Dictionary] = generate_rows()
	for row_index: int in range(_expected.size()):
		var expected_output: int = 1 if rows[row_index]["output"] else 0
		if _expected[row_index] != -1 and _expected[row_index] != expected_output:
			return false
		if _expected[row_index] == -1 and _answers[row_index] != expected_output:
			return false
	return true


## Returns true when all blank cells have been answered.
func is_complete() -> bool:
	for row_index: int in range(_expected.size()):
		if _expected[row_index] == -1 and _answers[row_index] == -1:
			return false
	return true

