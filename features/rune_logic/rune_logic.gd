## Pure acyclic Boolean-network rules. This class has no Node/autoload dependencies.
class_name RuneLogic
extends RefCounted

var level: RuneLevel
var nodes: Dictionary[StringName, RuneNodeDef] = {}
var input_values: Dictionary[StringName, bool] = {}
var placed_gates: Dictionary[StringName, RuneNodeDef.RuneGateType] = {}
var tray_counts: Dictionary[int, int] = {}
var moves: int = 0
var hints_used: int = 0
var hint_cost: float = 1.0
var has_error: bool = false
var last_error: String = ""


func setup(p_level: RuneLevel, faction_bonus: FactionData = null) -> bool:
	if p_level == null:
		return _set_error("RuneLogic: level must not be null.")
	var new_nodes: Dictionary[StringName, RuneNodeDef] = {}
	var new_inputs: Dictionary[StringName, bool] = {}
	for node: RuneNodeDef in p_level.nodes:
		if node == null or node.id == &"":
			return _set_error("RuneLogic: node definitions require non-empty ids.")
		if new_nodes.has(node.id):
			return _set_error("RuneLogic: duplicate node id '%s'." % String(node.id))
		new_nodes[node.id] = node
		if node.gate_type == RuneNodeDef.RuneGateType.INPUT:
			new_inputs[node.id] = node.initial_value
	if not new_nodes.has(p_level.output_node_id):
		return _set_error("RuneLogic: output node '%s' does not exist." % String(p_level.output_node_id))
	if new_nodes[p_level.output_node_id].gate_type != RuneNodeDef.RuneGateType.OUTPUT:
		return _set_error("RuneLogic: output node '%s' is not an OUTPUT." % String(p_level.output_node_id))
	if p_level.par_moves < 0 or p_level.three_star_moves < 0 or p_level.two_star_moves < 0 or p_level.one_star_moves < 0:
		return _set_error("RuneLogic: move thresholds cannot be negative.")
	if p_level.three_star_moves > 0 and p_level.two_star_moves > 0 and p_level.three_star_moves > p_level.two_star_moves:
		return _set_error("RuneLogic: three-star threshold must not exceed the two-star threshold.")
	if p_level.two_star_moves > 0 and p_level.one_star_moves > 0 and p_level.two_star_moves > p_level.one_star_moves:
		return _set_error("RuneLogic: two-star threshold must not exceed the one-star threshold.")
	if p_level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE and p_level.truth_table_input_ids.is_empty():
		return _set_error("RuneLogic: truth-table levels require at least one input.")

	var counts: Dictionary[int, int] = {}
	for gate: RuneNodeDef.RuneGateType in p_level.tray:
		if not _is_placeable_gate(gate):
			return _set_error("RuneLogic: tray only accepts AND, OR, and NOT gates.")
		counts[gate] = int(counts.get(gate, 0)) + 1
	for node: RuneNodeDef in p_level.nodes:
		if node.gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT:
			if node.locked:
				return _set_error("RuneLogic: empty gate slots cannot be locked.")
			if not _valid_slot_input_count(node.input_node_ids, p_level.tray):
				return _set_error("RuneLogic: gate slots require an input count compatible with a tray gate.")
		elif not _valid_gate_input_count(node.input_node_ids, node.gate_type):
			return _set_error("RuneLogic: node '%s' has an invalid number of inputs." % String(node.id))
		for input_id: StringName in node.input_node_ids:
			if not new_nodes.has(input_id):
				return _set_error("RuneLogic: node '%s' references missing input '%s'." % [String(node.id), String(input_id)])

	level = p_level
	nodes = new_nodes
	input_values = new_inputs
	placed_gates.clear()
	tray_counts = counts
	moves = 0
	hints_used = 0
	hint_cost = 1.0
	if faction_bonus != null:
		hint_cost = 1.0 - float(clampi(faction_bonus.hint_discount, 0, 100)) / 100.0
	has_error = false
	last_error = ""
	var evaluated: Dictionary[StringName, bool] = evaluate()
	return not has_error and evaluated.size() == nodes.size()


func evaluate(input_overrides: Dictionary[StringName, bool] = {}) -> Dictionary[StringName, bool]:
	var values: Dictionary[StringName, bool] = {}
	if level == null:
		_set_error("RuneLogic: call setup() before evaluate().")
		return values
	has_error = false
	last_error = ""
	var indegree: Dictionary[StringName, int] = {}
	var dependents: Dictionary[StringName, Array] = {}
	for id: StringName in nodes:
		indegree[id] = nodes[id].input_node_ids.size()
		dependents[id] = []
	for id: StringName in nodes:
		for input_id: StringName in nodes[id].input_node_ids:
			var children: Array = dependents[input_id]
			children.append(id)
			dependents[input_id] = children
	var ready: Array[StringName] = []
	for id: StringName in nodes:
		if int(indegree[id]) == 0:
			ready.append(id)
	var order: Array[StringName] = []
	while not ready.is_empty():
		var id: StringName = ready.pop_front()
		order.append(id)
		var children: Array = dependents[id]
		for child_value: Variant in children:
			var child: StringName = child_value as StringName
			indegree[child] = int(indegree[child]) - 1
			if int(indegree[child]) == 0:
				ready.append(child)
	if order.size() != nodes.size():
		_set_error("RuneLogic: cycle detected in gate network.")
		return values

	for id: StringName in order:
		var node: RuneNodeDef = nodes[id]
		var gate_type: RuneNodeDef.RuneGateType = node.gate_type
		if gate_type == RuneNodeDef.RuneGateType.INPUT:
			values[id] = input_overrides.get(id, input_values.get(id, node.initial_value))
			continue
		if gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT:
			if not placed_gates.has(id):
				values[id] = false
				continue
			gate_type = placed_gates[id]
		var operands: Array[bool] = []
		for input_id: StringName in node.input_node_ids:
			operands.append(values[input_id])
		match gate_type:
			RuneNodeDef.RuneGateType.AND:
				values[id] = _all_true(operands)
			RuneNodeDef.RuneGateType.OR:
				values[id] = _any_true(operands)
			RuneNodeDef.RuneGateType.NOT:
				values[id] = not operands[0]
			RuneNodeDef.RuneGateType.OUTPUT:
				values[id] = operands[0]
			_:
				_set_error("RuneLogic: unsupported gate type on node '%s'." % String(id))
				return {}
	return values


func is_solved() -> bool:
	if level == null or has_error or not _all_slots_filled():
		return false
	var values: Dictionary[StringName, bool] = evaluate()
	return not has_error and values.has(level.output_node_id) and values[level.output_node_id] == level.target_value


func toggle_input(id: StringName) -> bool:
	if not nodes.has(id) or nodes[id].gate_type != RuneNodeDef.RuneGateType.INPUT or nodes[id].locked:
		return false
	input_values[id] = not input_values[id]
	moves += 1
	return true


func place_gate(slot_id: StringName, gate_type: RuneNodeDef.RuneGateType) -> bool:
	if not nodes.has(slot_id) or nodes[slot_id].gate_type != RuneNodeDef.RuneGateType.EMPTY_SLOT:
		return false
	if not _is_placeable_gate(gate_type) or int(tray_counts.get(gate_type, 0)) <= 0:
		return false
	if not _valid_gate_input_count(nodes[slot_id].input_node_ids, gate_type):
		return false
	if placed_gates.has(slot_id):
		return false
	tray_counts[gate_type] = int(tray_counts[gate_type]) - 1
	placed_gates[slot_id] = gate_type
	moves += 1
	return true


func remove_gate(slot_id: StringName) -> bool:
	if not placed_gates.has(slot_id):
		return false
	var gate_type: RuneNodeDef.RuneGateType = placed_gates[slot_id]
	placed_gates.erase(slot_id)
	tray_counts[gate_type] = int(tray_counts.get(gate_type, 0)) + 1
	moves += 1
	return true


func get_hint(solution: Dictionary[StringName, Variant] = {}) -> StringName:
	if level == null or is_solved():
		return &""
	var target: Dictionary[StringName, Variant] = solution
	if target.is_empty():
		target = RuneLevelSolver.solve(level)
	for id: StringName in nodes:
		var node: RuneNodeDef = nodes[id]
		if node.gate_type == RuneNodeDef.RuneGateType.INPUT and not node.locked and target.has(id):
			if input_values.get(id, false) != bool(target[id]):
				return id
		if node.gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT and target.has(id):
			if not placed_gates.has(id) or placed_gates[id] != int(target[id]):
				return id
	return &""


func register_hint() -> bool:
	if get_hint() == &"":
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


func _all_slots_filled() -> bool:
	for id: StringName in nodes:
		if nodes[id].gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT and not placed_gates.has(id):
			return false
	return true


func _set_error(message: String) -> bool:
	has_error = true
	last_error = message
	push_error(message)
	return false


static func _is_placeable_gate(gate_type: RuneNodeDef.RuneGateType) -> bool:
	return gate_type == RuneNodeDef.RuneGateType.AND or gate_type == RuneNodeDef.RuneGateType.OR or gate_type == RuneNodeDef.RuneGateType.NOT


static func _valid_gate_input_count(inputs: Array[StringName], gate_type: RuneNodeDef.RuneGateType) -> bool:
	match gate_type:
		RuneNodeDef.RuneGateType.INPUT:
			return inputs.is_empty()
		RuneNodeDef.RuneGateType.AND, RuneNodeDef.RuneGateType.OR, RuneNodeDef.RuneGateType.EMPTY_SLOT:
			return inputs.size() >= 2
		RuneNodeDef.RuneGateType.NOT, RuneNodeDef.RuneGateType.OUTPUT:
			return inputs.size() == 1
	return false


static func _valid_slot_input_count(
	inputs: Array[StringName],
	tray: Array[RuneNodeDef.RuneGateType]
) -> bool:
	for gate_type: RuneNodeDef.RuneGateType in tray:
		if _valid_gate_input_count(inputs, gate_type):
			return true
	return false


static func _all_true(values: Array[bool]) -> bool:
	for value: bool in values:
		if not value:
			return false
	return true


static func _any_true(values: Array[bool]) -> bool:
	for value: bool in values:
		if value:
			return true
	return false
