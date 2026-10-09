## Headless tests for Boolean gates, rune networks, and truth tables.
## Run with: godot --headless -s res://tests/test_rune_logic.gd
extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_test_gate_truth_tables()
	_test_chained_network_and_cycles()
	_test_set_inputs_and_hints()
	_test_place_gates()
	_test_truth_table_answers()
	_test_all_shipped_levels()
	print("\nRuneLogic: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_gate_truth_tables() -> void:
	print("TEST: AND, OR, and NOT truth tables")
	var and_logic: RuneLogic = RuneLogic.new()
	var and_level: RuneLevel = _gate_level(RuneNodeDef.RuneGateType.AND, 2)
	_check(and_logic.setup(and_level), "AND network sets up")
	_check(_output(and_logic, {&"a": false, &"b": false}) == false, "AND false/false is false")
	_check(_output(and_logic, {&"a": false, &"b": true}) == false, "AND false/true is false")
	_check(_output(and_logic, {&"a": true, &"b": false}) == false, "AND true/false is false")
	_check(_output(and_logic, {&"a": true, &"b": true}) == true, "AND true/true is true")

	var or_logic: RuneLogic = RuneLogic.new()
	_check(or_logic.setup(_gate_level(RuneNodeDef.RuneGateType.OR, 2)), "OR network sets up")
	_check(_output(or_logic, {&"a": false, &"b": false}) == false, "OR false/false is false")
	_check(_output(or_logic, {&"a": false, &"b": true}) == true, "OR false/true is true")
	_check(_output(or_logic, {&"a": true, &"b": false}) == true, "OR true/false is true")
	_check(_output(or_logic, {&"a": true, &"b": true}) == true, "OR true/true is true")

	var not_logic: RuneLogic = RuneLogic.new()
	_check(not_logic.setup(_gate_level(RuneNodeDef.RuneGateType.NOT, 1)), "NOT network sets up")
	_check(_output(not_logic, {&"a": false}) == true, "NOT false is true")
	_check(_output(not_logic, {&"a": true}) == false, "NOT true is false")


func _test_chained_network_and_cycles() -> void:
	print("TEST: chained evaluation and cycle detection")
	var level: RuneLevel = RuneLevel.new()
	level.id = "test_chain"
	level.nodes = [
		_make_node(&"a", RuneNodeDef.RuneGateType.INPUT),
		_make_node(&"b", RuneNodeDef.RuneGateType.INPUT),
		_make_node(&"and", RuneNodeDef.RuneGateType.AND, [&"a", &"b"]),
		_make_node(&"not", RuneNodeDef.RuneGateType.NOT, [&"and"]),
		_make_node(&"output", RuneNodeDef.RuneGateType.OUTPUT, [&"not"]),
	]
	var logic: RuneLogic = RuneLogic.new()
	_check(logic.setup(level), "chained network sets up")
	_check(_output(logic, {&"a": true, &"b": true}) == false, "chained AND then NOT evaluates false")
	_check(_output(logic, {&"a": true, &"b": false}) == true, "chained AND then NOT evaluates true")

	var cycle: RuneLevel = RuneLevel.new()
	cycle.id = "test_cycle"
	cycle.output_node_id = &"output"
	cycle.nodes = [
		_make_node(&"not", RuneNodeDef.RuneGateType.NOT, [&"output"]),
		_make_node(&"output", RuneNodeDef.RuneGateType.OUTPUT, [&"not"]),
	]
	var cycle_logic: RuneLogic = RuneLogic.new()
	_check(not cycle_logic.setup(cycle), "cycle is rejected during setup")
	_check(cycle_logic.has_error and cycle_logic.last_error.contains("cycle"), "cycle error is explicit")


func _test_set_inputs_and_hints() -> void:
	print("TEST: SET_INPUTS, moves, and hints")
	var level: RuneLevel = _load_level(1)
	var logic: RuneLogic = RuneLogic.new()
	_check(logic.setup(level), "SET_INPUTS level sets up")
	_check(not logic.is_solved(), "SET_INPUTS puzzle starts unsolved")
	var hint: StringName = logic.get_hint()
	_check(hint != &"", "solver suggests a valid input to change")
	_check(logic.register_hint(), "hint can be recorded")
	_check(logic.hints_used == 1 and logic.moves == 0, "hint usage is tracked separately")
	_check(logic.toggle_input(hint), "suggested input can be toggled")
	_check(logic.moves == 1 and logic.is_solved(), "toggling the hinted input solves the gate")
	_check(logic.calculate_stars() == 2, "hint penalty reduces star score")
	var locked_level: RuneLevel = _load_level(4)
	var locked_logic: RuneLogic = RuneLogic.new()
	_check(locked_logic.setup(locked_level), "locked-input gate-placement level sets up")
	_check(not locked_logic.toggle_input(&"a"), "locked input cannot toggle")


func _test_place_gates() -> void:
	print("TEST: PLACE_GATES inventory and solving")
	var level: RuneLevel = _load_level(4).duplicate(true) as RuneLevel
	level.tray.append(RuneNodeDef.RuneGateType.NOT)
	var logic: RuneLogic = RuneLogic.new()
	_check(logic.setup(level), "PLACE_GATES level sets up")
	var solution: Dictionary[StringName, Variant] = RuneLevelSolver.solve(level)
	_check(solution.has(&"slot"), "brute-force solver finds a gate placement")
	var gate_type: RuneNodeDef.RuneGateType = int(solution[&"slot"]) as RuneNodeDef.RuneGateType
	var incompatible_gate: RuneNodeDef.RuneGateType = (
		RuneNodeDef.RuneGateType.NOT
		if gate_type != RuneNodeDef.RuneGateType.NOT
		else RuneNodeDef.RuneGateType.AND
	)
	_check(not logic.place_gate(&"slot", incompatible_gate), "slot rejects a gate with the wrong arity")
	_check(int(logic.tray_counts[incompatible_gate]) == 1, "rejected gate remains in the tray")
	_check(logic.place_gate(&"slot", gate_type), "correct gate can be placed")
	_check(not logic.place_gate(&"slot", gate_type), "occupied slot rejects a second gate")
	_check(logic.is_solved(), "placed gate solves the network")
	_check(logic.remove_gate(&"slot"), "placed gate can be removed")
	_check(not logic.is_solved(), "removing the gate reopens the slot")
	_check(int(logic.tray_counts[gate_type]) == 1, "removed gate returns to tray")


func _test_truth_table_answers() -> void:
	print("TEST: truth table generation and missing-answer validation")
	var level: RuneLevel = _load_level(7)
	var table: TruthTableLogic = TruthTableLogic.new()
	_check(table.setup(level), "AND truth table generates")
	_check(table.rows.size() == 4, "two inputs generate four rows")
	_check(not table.is_solved(), "unanswered truth table is incomplete")
	var hint: int = table.get_hint()
	_check(hint >= 0 and level.truth_table_missing_rows.has(hint), "truth-table hint identifies a blank row")
	_check(table.register_hint(), "truth-table hint can be recorded")
	for row_index: int in level.truth_table_missing_rows:
		var expected: bool = bool(table.rows[row_index]["expected"])
		_check(table.set_answer(row_index, expected), "truth row %d can be answered" % row_index)
	_check(table.is_solved(), "all correct AND rows solve the table")
	_check(table.calculate_stars() == 3, "hint penalty is included in table star scoring")
	_check(not table.set_answer(0, false), "known rows cannot be overwritten")

	var not_table: TruthTableLogic = TruthTableLogic.new()
	_check(not_table.setup(_load_level(8)), "NOT truth table generates")
	_check(not_table.rows.size() == 2, "one input generates two rows")
	_check(not_table.set_answer(1, false), "missing NOT output accepts the correct value")
	_check(not_table.moves == 1, "selecting FALSE directly costs one move")
	_check(not_table.is_solved(), "correct NOT table is complete")
	_check(not_table.calculate_stars() == 3, "one direct FALSE answer earns three stars")


func _test_all_shipped_levels() -> void:
	print("TEST: all ten authored rune levels are solvable")
	for index: int in range(1, 11):
		var level: RuneLevel = _load_level(index)
		_check(level != null, "rune level %02d loads" % index)
		if level == null:
			continue
		var solution: Dictionary[StringName, Variant] = RuneLevelSolver.solve(level)
		_check(not solution.is_empty(), "rune level %02d has a valid solver result" % index)
		if level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE:
			var table: TruthTableLogic = TruthTableLogic.new()
			_check(table.setup(level), "rune level %02d truth table initializes" % index)
			for row_index: int in level.truth_table_missing_rows:
				var row_key: StringName = StringName("row_%d" % row_index)
				_check(solution.has(row_key), "rune level %02d solver fills row %d" % [index, row_index])
				_check(table.set_answer(row_index, bool(solution[row_key])), "rune level %02d accepts row %d" % [index, row_index])
			_check(table.is_solved(), "rune level %02d table solution is correct" % index)
		else:
			var logic: RuneLogic = RuneLogic.new()
			_check(logic.setup(level), "rune level %02d network initializes" % index)
			_check(not logic.is_solved(), "rune level %02d starts incomplete" % index)
			for id: StringName in solution:
				var node: RuneNodeDef = logic.nodes[id]
				if node.gate_type == RuneNodeDef.RuneGateType.INPUT:
					logic.input_values[id] = bool(solution[id])
				elif node.gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT:
					var gate_type: RuneNodeDef.RuneGateType = int(solution[id]) as RuneNodeDef.RuneGateType
					_check(logic.place_gate(id, gate_type), "rune level %02d solution gate is placeable" % index)
			_check(logic.is_solved(), "rune level %02d solver result opens output" % index)
			_check(
				_solution_minimum_moves(level, solution) <= level.three_star_moves,
				"rune level %02d par supports its solution" % index
			)


func _solution_minimum_moves(level: RuneLevel, solution: Dictionary[StringName, Variant]) -> int:
	var moves: int = 0
	for id: StringName in solution:
		var node: RuneNodeDef = null
		for candidate: RuneNodeDef in level.nodes:
			if candidate.id == id:
				node = candidate
				break
		if node == null:
			continue
		if node.gate_type == RuneNodeDef.RuneGateType.INPUT and node.initial_value != bool(solution[id]):
			moves += 1
		elif node.gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT:
			moves += 1
	return moves


func _gate_level(gate_type: RuneNodeDef.RuneGateType, input_count: int) -> RuneLevel:
	var level: RuneLevel = RuneLevel.new()
	level.id = "test_gate"
	var inputs: Array[StringName] = []
	for index: int in range(input_count):
		var id: StringName = StringName("a" if index == 0 else "b")
		inputs.append(id)
		level.nodes.append(_make_node(id, RuneNodeDef.RuneGateType.INPUT))
	var gate_id: StringName = &"gate"
	level.nodes.append(_make_node(gate_id, gate_type, inputs))
	level.nodes.append(_make_node(&"output", RuneNodeDef.RuneGateType.OUTPUT, [gate_id]))
	return level


func _load_level(index: int) -> RuneLevel:
	var path: String = "res://data/puzzles/runes/runes_%02d.tres" % index
	var level: RuneLevel = load(path) as RuneLevel
	if level == null:
		_fail("Cannot load %s" % path)
	return level


func _make_node(
	id: StringName,
	gate_type: RuneNodeDef.RuneGateType,
	input_ids: Array[StringName] = []
) -> RuneNodeDef:
	var node: RuneNodeDef = RuneNodeDef.new()
	node.id = id
	node.gate_type = gate_type
	node.input_node_ids = input_ids
	return node


func _output(logic: RuneLogic, input_values: Dictionary[StringName, bool]) -> bool:
	var values: Dictionary[StringName, bool] = logic.evaluate(input_values)
	return bool(values.get(logic.level.output_node_id, false))


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
	else:
		_fail(description)


func _fail(description: String) -> void:
	_failed += 1
	push_error("FAIL: %s" % description)
