## Exhaustive solver for small rune networks, used by tests and content tools.
class_name RuneLevelSolver
extends RefCounted


static func solve(level: RuneLevel) -> Dictionary[StringName, Variant]:
	var solution: Dictionary[StringName, Variant] = {}
	if level == null:
		push_error("RuneLevelSolver: level must not be null.")
		return solution
	if level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE:
		var table: TruthTableLogic = TruthTableLogic.new()
		if not table.setup(level):
			return solution
		for row_index: int in level.truth_table_missing_rows:
			solution[StringName("row_%d" % row_index)] = bool(table.rows[row_index]["expected"])
		return solution

	var logic: RuneLogic = RuneLogic.new()
	if not logic.setup(level):
		return solution
	var input_ids: Array[StringName] = []
	var slot_ids: Array[StringName] = []
	for id: StringName in logic.nodes:
		var node: RuneNodeDef = logic.nodes[id]
		if node.gate_type == RuneNodeDef.RuneGateType.INPUT and not node.locked:
			input_ids.append(id)
		elif node.gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT:
			slot_ids.append(id)
	if input_ids.size() > 10 or slot_ids.size() > 7:
		push_error("RuneLevelSolver: level '%s' exceeds exhaustive-search limits." % level.id)
		return solution
	var gate_types: Array[RuneNodeDef.RuneGateType] = [
		RuneNodeDef.RuneGateType.AND,
		RuneNodeDef.RuneGateType.OR,
		RuneNodeDef.RuneGateType.NOT,
	]
	var input_combinations: int = 1 << input_ids.size()
	for input_mask: int in range(input_combinations):
		for index: int in range(input_ids.size()):
			logic.input_values[input_ids[index]] = ((input_mask >> index) & 1) == 1
		if _search_slots(0, slot_ids, gate_types, logic):
			for id: StringName in input_ids:
				solution[id] = logic.input_values[id]
			for id: StringName in slot_ids:
				solution[id] = int(logic.placed_gates[id])
			return solution
	return solution


static func _search_slots(
	index: int,
	slot_ids: Array[StringName],
	gate_types: Array[RuneNodeDef.RuneGateType],
	logic: RuneLogic
) -> bool:
	if index >= slot_ids.size():
		var values: Dictionary[StringName, bool] = logic.evaluate()
		return not logic.has_error and values.has(logic.level.output_node_id) and values[logic.level.output_node_id] == logic.level.target_value
	var slot_id: StringName = slot_ids[index]
	var remaining: Array[RuneNodeDef.RuneGateType] = []
	for gate_type: RuneNodeDef.RuneGateType in gate_types:
		for count: int in range(int(logic.tray_counts.get(gate_type, 0))):
			remaining.append(gate_type)
	for gate_type: RuneNodeDef.RuneGateType in remaining:
		if not logic.place_gate(slot_id, gate_type):
			continue
		if _search_slots(index + 1, slot_ids, gate_types, logic):
			return true
		logic.remove_gate(slot_id)
	return false
