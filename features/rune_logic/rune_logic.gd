## Pure evaluator and state model for a rune circuit.
class_name RuneLogic
extends RefCounted


## Emitted when a player action changes the circuit.
signal state_changed
## Emitted when the circuit first reaches its target.
signal solved

## Level whose circuit is being played.
var level: RuneLevel
## Error from the most recent graph evaluation, empty when valid.
var last_error: String = ""
## Number of successful player actions.
var moves: int = 0
## Number of hints requested.
var hints_used: int = 0

var _gate_types: Dictionary[StringName, int] = {}
var _input_values: Dictionary[StringName, bool] = {}
var _remaining_tray: Array[int] = []
var _solution_types: Dictionary[StringName, int] = {}
var _solution_inputs: Dictionary[StringName, bool] = {}
var _was_solved: bool = false


## Creates a circuit from a level resource.
func _init(source_level: RuneLevel = null) -> void:
	if source_level != null:
		configure(source_level)


## Resets this logic instance to the level's initial state.
func configure(source_level: RuneLevel) -> void:
	assert(source_level != null and source_level.validate_level(), "Invalid rune level")
	level = source_level
	moves = 0
	hints_used = 0
	last_error = ""
	_was_solved = false
	_gate_types.clear()
	_input_values.clear()
	_remaining_tray = source_level.tray.duplicate()
	for node_data: RuneNodeData in source_level.nodes:
		_gate_types[node_data.id] = node_data.gate_type
		if node_data.gate_type == RuneGateType.Type.INPUT:
			_input_values[node_data.id] = node_data.initial_value


## Evaluates every node in topological order; returns empty and sets last_error on cycles.
func evaluate() -> Dictionary[StringName, bool]:
	last_error = ""
	var order: Array[StringName] = []
	var visit_state: Dictionary[StringName, int] = {}
	for node_data: RuneNodeData in level.nodes:
		if not _visit(node_data.id, visit_state, order):
			last_error = "cycle"
			return {}
	var values: Dictionary[StringName, bool] = {}
	for node_id: StringName in order:
		var node_data: RuneNodeData = _find_node(node_id)
		var gate_type: int = _gate_types[node_id]
		if not _evaluate_node(node_data, gate_type, values):
			if last_error != "empty_slot":
				return {}
			values[node_id] = false
	return values


## Returns whether the designated OUTPUT node equals the level target.
func is_solved() -> bool:
	var values: Dictionary[StringName, bool] = evaluate()
	if not last_error.is_empty() or values.is_empty():
		return false
	var output_node: RuneNodeData = _find_output()
	if output_node == null:
		last_error = "missing_output"
		return false
	return values.get(output_node.id, false) == level.target_value


## Toggles an editable input and counts the move.
func toggle_input(node_id: StringName) -> bool:
	var node_data: RuneNodeData = _find_node(node_id)
	if node_data == null or node_data.gate_type != RuneGateType.Type.INPUT or node_data.locked:
		return false
	_input_values[node_id] = not _input_values[node_id]
	_register_move()
	return true


## Places a gate from the tray into a compatible empty slot.
func place_gate(slot_id: StringName, gate_type: int) -> bool:
	var slot: RuneNodeData = _find_node(slot_id)
	if slot == null or slot.locked or _gate_types[slot_id] != RuneGateType.Type.EMPTY_SLOT:
		return false
	var tray_index: int = _remaining_tray.find(gate_type)
	if tray_index < 0 or not _gate_arity_matches(slot, gate_type):
		return false
	_remaining_tray.remove_at(tray_index)
	_gate_types[slot_id] = gate_type
	_register_move()
	return true


## Removes a placed gate and returns it to the tray.
func remove_gate(slot_id: StringName) -> bool:
	var slot: RuneNodeData = _find_node(slot_id)
	if slot == null or slot.locked:
		return false
	var gate_type: int = _gate_types[slot_id]
	if gate_type == RuneGateType.Type.EMPTY_SLOT or gate_type == RuneGateType.Type.INPUT or gate_type == RuneGateType.Type.OUTPUT:
		return false
	_remaining_tray.append(gate_type)
	_gate_types[slot_id] = RuneGateType.Type.EMPTY_SLOT
	_register_move()
	return true


## Returns an actionable one-change hint for the current circuit.
func get_hint() -> Dictionary:
	hints_used += 1
	for node_data: RuneNodeData in level.nodes:
		if node_data.gate_type == RuneGateType.Type.INPUT and not node_data.locked:
			var before: bool = _input_values[node_data.id]
			_input_values[node_data.id] = not before
			var solves: bool = is_solved()
			_input_values[node_data.id] = before
			if solves:
				return {"kind": "input", "node_id": node_data.id, "value": not before}
	for node_data: RuneNodeData in level.nodes:
		if _gate_types[node_data.id] != RuneGateType.Type.EMPTY_SLOT or _remaining_tray.is_empty():
			continue
		for gate_type: int in _remaining_tray:
			if not _gate_arity_matches(node_data, gate_type):
				continue
			var old_type: int = _gate_types[node_data.id]
			_gate_types[node_data.id] = gate_type
			var solves: bool = is_solved()
			_gate_types[node_data.id] = old_type
			if solves:
				return {"kind": "gate", "node_id": node_data.id, "gate_type": gate_type}
	if brute_force_solve():
		for node_data: RuneNodeData in level.nodes:
			if node_data.gate_type == RuneGateType.Type.INPUT and not node_data.locked:
				var desired_value: bool = _solution_inputs.get(node_data.id, _input_values.get(node_data.id, false))
				if desired_value != _input_values.get(node_data.id, false):
					return {"kind": "input", "node_id": node_data.id, "value": desired_value}
		for node_data: RuneNodeData in level.nodes:
			if _gate_types[node_data.id] == RuneGateType.Type.EMPTY_SLOT:
				return {"kind": "gate", "node_id": node_data.id, "gate_type": _solution_types[node_data.id]}
	return {"kind": "inspect", "node_id": _find_output().id if _find_output() != null else &""}


## Returns the current star rating based on move thresholds.
func get_stars() -> int:
	if not is_solved():
		return 0
	if moves <= level.three_star_moves:
		return 3
	if moves <= level.two_star_moves:
		return 2
	return 1


## Exhaustively checks editable inputs and tray gate arrangements without mutating state.
func brute_force_solve() -> bool:
	_solution_types.clear()
	_solution_inputs.clear()
	var input_ids: Array[StringName] = []
	for node_data: RuneNodeData in level.nodes:
		if node_data.gate_type == RuneGateType.Type.INPUT and not node_data.locked:
			input_ids.append(node_data.id)
	var combinations: int = 1 << input_ids.size()
	for mask: int in range(combinations):
		var candidate_inputs: Dictionary[StringName, bool] = _input_values.duplicate()
		for index: int in range(input_ids.size()):
			candidate_inputs[input_ids[index]] = (mask & (1 << index)) != 0
		if _search_tray(0, _remaining_tray.duplicate(), _gate_types.duplicate(), candidate_inputs):
			return true
	return false


## Returns a copy of the available gate tray.
func get_remaining_tray() -> Array[int]:
	return _remaining_tray.duplicate()


## Returns the current type of a node.
func get_gate_type(node_id: StringName) -> int:
	return _gate_types.get(node_id, RuneGateType.Type.EMPTY_SLOT)


## Returns the currently evaluated node values.
func get_input_value(node_id: StringName) -> bool:
	return _input_values.get(node_id, false)


func _register_move() -> void:
	moves += 1
	state_changed.emit()
	if is_solved():
		if not _was_solved:
			_was_solved = true
			solved.emit()


func _visit(node_id: StringName, visit_state: Dictionary[StringName, int], order: Array[StringName]) -> bool:
	var state: int = visit_state.get(node_id, 0)
	if state == 1:
		return false
	if state == 2:
		return true
	visit_state[node_id] = 1
	var node_data: RuneNodeData = _find_node(node_id)
	if node_data != null:
		for input_id: StringName in node_data.input_ids:
			if not _visit(input_id, visit_state, order):
				return false
	visit_state[node_id] = 2
	order.append(node_id)
	return true


func _evaluate_node(node_data: RuneNodeData, gate_type: int, values: Dictionary[StringName, bool]) -> bool:
	if gate_type == RuneGateType.Type.INPUT:
		values[node_data.id] = _input_values.get(node_data.id, false)
		return true
	if gate_type == RuneGateType.Type.EMPTY_SLOT:
		last_error = "empty_slot"
		return false
	match gate_type:
		RuneGateType.Type.OUTPUT:
			values[node_data.id] = values.get(node_data.input_ids[0], false) if not node_data.input_ids.is_empty() else false
		RuneGateType.Type.NOT:
			var source_val: bool = values.get(node_data.input_ids[0], false) if not node_data.input_ids.is_empty() else false
			values[node_data.id] = not source_val
		RuneGateType.Type.AND:
			var and_val: bool = true
			for input_id: StringName in node_data.input_ids:
				and_val = and_val and values.get(input_id, false)
			values[node_data.id] = and_val
		RuneGateType.Type.OR:
			var or_val: bool = false
			for input_id: StringName in node_data.input_ids:
				or_val = or_val or values.get(input_id, false)
			values[node_data.id] = or_val
	return true


func _search_tray(index: int, tray: Array[int], candidate_types: Dictionary[StringName, int], candidate_inputs: Dictionary[StringName, bool]) -> bool:
	if index >= level.nodes.size():
		var values: Dictionary[StringName, bool] = _evaluate_candidate(candidate_types, candidate_inputs)
		var output_node: RuneNodeData = _find_output()
		if output_node != null and values.get(output_node.id, false) == level.target_value:
			_solution_types = candidate_types.duplicate()
			_solution_inputs = candidate_inputs.duplicate()
			return true
		return false

	var node_data: RuneNodeData = level.nodes[index]
	if _gate_types[node_data.id] != RuneGateType.Type.EMPTY_SLOT:
		return _search_tray(index + 1, tray, candidate_types, candidate_inputs)

	for tray_index: int in range(tray.size()):
		var gate_type: int = tray[tray_index]
		if not _gate_arity_matches(node_data, gate_type):
			continue
		var remaining: Array[int] = tray.duplicate()
		remaining.remove_at(tray_index)
		candidate_types[node_data.id] = gate_type
		if _search_tray(index + 1, remaining, candidate_types, candidate_inputs):
			return true
		candidate_types[node_data.id] = RuneGateType.Type.EMPTY_SLOT
	return false


func _evaluate_candidate(candidate_types: Dictionary[StringName, int], candidate_inputs: Dictionary[StringName, bool]) -> Dictionary[StringName, bool]:
	var values: Dictionary[StringName, bool] = {}
	var order: Array[StringName] = []
	var visit_state: Dictionary[StringName, int] = {}
	for node_data: RuneNodeData in level.nodes:
		if not _visit(node_data.id, visit_state, order):
			return {}
	for node_id: StringName in order:
		var node_data: RuneNodeData = _find_node(node_id)
		var gate_type: int = candidate_types[node_id]
		if gate_type == RuneGateType.Type.INPUT:
			values[node_id] = candidate_inputs.get(node_id, false)
		elif gate_type == RuneGateType.Type.EMPTY_SLOT:
			values[node_id] = false
		elif gate_type == RuneGateType.Type.OUTPUT:
			values[node_id] = values.get(node_data.input_ids[0], false) if not node_data.input_ids.is_empty() else false
		elif gate_type == RuneGateType.Type.NOT:
			values[node_id] = not (values.get(node_data.input_ids[0], false) if not node_data.input_ids.is_empty() else false)
		elif gate_type == RuneGateType.Type.AND:
			var and_val: bool = true
			for input_id: StringName in node_data.input_ids:
				and_val = and_val and values.get(input_id, false)
			values[node_id] = and_val
		elif gate_type == RuneGateType.Type.OR:
			var or_val: bool = false
			for input_id: StringName in node_data.input_ids:
				or_val = or_val or values.get(input_id, false)
			values[node_id] = or_val
	return values


func _gate_arity_matches(slot: RuneNodeData, gate_type: int) -> bool:
	if gate_type == RuneGateType.Type.NOT:
		return slot.input_ids.size() == 1
	return (gate_type == RuneGateType.Type.AND or gate_type == RuneGateType.Type.OR) and slot.input_ids.size() >= 2


func _find_node(node_id: StringName) -> RuneNodeData:
	for node_data: RuneNodeData in level.nodes:
		if node_data.id == node_id:
			return node_data
	return null


func _find_output() -> RuneNodeData:
	for node_data: RuneNodeData in level.nodes:
		if _gate_types[node_data.id] == RuneGateType.Type.OUTPUT:
			return node_data
	return null