## Touch-first presentation and integration for all rune puzzle modes.
class_name RunePuzzle
extends SafeAreaContainer


## Emitted when a level is completed.
signal level_finished(result: PuzzleResult)
## Emitted when the player leaves the puzzle.
signal exit_requested

const NODE_SCENE: PackedScene = preload("res://features/rune_logic/rune_node.tscn")
const BOARD_NODE_SIZE: Vector2 = Vector2(112.0, 112.0)

@export var asset_catalog: AssetCatalog = preload("res://data/asset_catalog.tres")
@export var sfx_solved: AudioStream
@export var sfx_error: AudioStream

var _level: RuneLevel
var _logic: RuneLogic
var _table_logic: TruthTableLogic
var _node_views: Dictionary[StringName, RuneNodeView] = {}
var _node_positions: Dictionary[StringName, Vector2] = {}
var _table_buttons: Array[Button] = []
var _screen: VBoxContainer
var _header_title: Label
var _intro_label: Label
var _target_label: Label
var _moves_label: Label
var _hints_label: Label
var _board: Control
var _wire_view: RuneWireView
var _table_container: VBoxContainer
var _tray_container: HBoxContainer
var _tray_label: Label
var _hint_button: Button
var _restart_button: Button
var _back_button: Button
var _selected_gate: RuneGateType.Type = RuneGateType.Type.EMPTY_SLOT
var _clue_index: int = 0
var _hints_used: int = 0
var _hint_discount: int = 0
var _started_at_msec: int = 0
var _finished: bool = false
var _popup_key: String = ""
var _popup_table_key: String = ""
var _popup_params: Dictionary = {}
var _popup_hint: Dictionary = {}
var _result_stars: int = 0
var _popup_layer: Control
var _popup_label: Label
var _popup_close_button: Button
var _result_layer: Control


## Builds the screen and starts the first data-driven level for standalone use.
func _ready() -> void:
	super._ready()
	if asset_catalog != null:
		sfx_solved = asset_catalog.sfx_rune_solved
		sfx_error = asset_catalog.sfx_rune_error
	_build_ui()
	EventBus.language_changed.connect(_on_language_changed)
	var first_level: Resource = ResourceLoader.load("res://data/puzzles/runes/runes_01.tres")
	if first_level is RuneLevel:
		start_level(first_level as RuneLevel)


## Starts or restarts a level without changing the public puzzle integration contract.
func start_level(level: RuneLevel) -> void:
	assert(level != null and level.validate_level(), "Invalid rune level")
	_level = level
	_logic = RuneLogic.new(level)
	_table_logic = TruthTableLogic.new(level) if level.mode == RuneLevel.Mode.TRUTH_TABLE else null
	_clue_index = 0
	_hints_used = 0
	_hint_discount = _get_hint_discount()
	_started_at_msec = Time.get_ticks_msec()
	_finished = false
	_selected_gate = RuneGateType.Type.EMPTY_SLOT
	_clear_result_panel()
	_refresh_ui()
	_rebuild_board()
	_rebuild_truth_table()
	_update_status()


func _build_ui() -> void:
	_screen = VBoxContainer.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.offset_left = 18.0
	_screen.offset_top = 18.0
	_screen.offset_right = -18.0
	_screen.offset_bottom = -18.0
	_screen.add_theme_constant_override("separation", 12)
	add_child(_screen)
	var header: HBoxContainer = HBoxContainer.new()
	_screen.add_child(header)
	_back_button = _make_button("ui.back", _on_back_pressed)
	header.add_child(_back_button)
	_header_title = Label.new()
	_header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_header_title)
	_restart_button = _make_button("ui.runes.restart", _on_restart_pressed)
	header.add_child(_restart_button)
	_intro_label = Label.new()
	_intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro_label.custom_minimum_size.y = 44.0
	_screen.add_child(_intro_label)
	var status_row: HBoxContainer = HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 12)
	_screen.add_child(status_row)
	_target_label = Label.new()
	_target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_row.add_child(_target_label)
	_moves_label = Label.new()
	moves_label_vertical(status_row)
	_hints_label = Label.new()
	status_row.add_child(_hints_label)
	_board = Control.new()
	_board.custom_minimum_size = Vector2(620.0, 410.0)
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen.add_child(_board)
	_wire_view = RuneWireView.new()
	_wire_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wire_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(_wire_view)
	_table_container = VBoxContainer.new()
	_table_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table_container.add_theme_constant_override("separation", 8)
	_screen.add_child(_table_container)
	_tray_label = Label.new()
	_screen.add_child(_tray_label)
	_tray_container = HBoxContainer.new()
	_tray_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_tray_container.add_theme_constant_override("separation", 16)
	_tray_container.custom_minimum_size.y = 96.0
	_screen.add_child(_tray_container)
	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 16)
	_screen.add_child(action_row)
	_hint_button = _make_button("ui.runes.hint", _on_hint_pressed)
	action_row.add_child(_hint_button)
	var info_button: Button = _make_button("ui.runes.gate_guide", _on_guide_pressed)
	action_row.add_child(info_button)
	_popup_layer = Control.new()
	_popup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_layer.visible = false
	add_child(_popup_layer)
	_result_layer = Control.new()
	_result_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_layer.visible = false
	add_child(_result_layer)


func _refresh_ui() -> void:
	if _level == null:
		return
	_header_title.text = Localization.translate(_level.title_key)
	_intro_label.text = Localization.translate(_level.intro_key)
	_back_button.text = Localization.translate("ui.back")
	_restart_button.text = Localization.translate("ui.runes.restart")
	_hint_button.text = Localization.translate("ui.runes.hint")
	_tray_label.text = Localization.translate("ui.runes.tray")
	for node_view: RuneNodeView in _node_views.values():
		node_view.refresh_locale()
	_update_status()
	_rebuild_truth_table()
	_refresh_popup()
	if _result_layer.visible:
		_show_result_panel(_result_stars)


func _rebuild_board() -> void:
	for child: Node in _board.get_children():
		if child != _wire_view:
			child.queue_free()
	_node_views.clear()
	_node_positions.clear()
	var column_count: int = 3
	for node_index: int in range(_level.nodes.size()):
		var node_data: RuneNodeData = _level.nodes[node_index]
		var column: int = node_index % column_count
		var row: int = node_index / column_count
		var center: Vector2 = Vector2(104.0 + float(column) * 206.0, 70.0 + float(row) * 136.0)
		_node_positions[node_data.id] = center
		var node_view: RuneNodeView = NODE_SCENE.instantiate() as RuneNodeView
		_apply_asset_slots(node_view)
		node_view.position = center - BOARD_NODE_SIZE * 0.5
		node_view.size = BOARD_NODE_SIZE
		node_view.node_activated.connect(_on_node_activated)
		node_view.info_requested.connect(_on_node_info_requested)
		_board.add_child(node_view)
		_node_views[node_data.id] = node_view
		_update_node_view(node_data.id)
	_update_wires()
	_board.custom_minimum_size.y = maxf(410.0, ceilf(float(_level.nodes.size()) / 3.0) * 136.0 + 8.0)
	_board.visible = _level.mode != RuneLevel.Mode.TRUTH_TABLE
	_table_container.visible = _level.mode == RuneLevel.Mode.TRUTH_TABLE
	_tray_label.visible = _level.mode == RuneLevel.Mode.PLACE_GATES
	_tray_container.visible = _level.mode == RuneLevel.Mode.PLACE_GATES


func _rebuild_truth_table() -> void:
	for child: Node in _table_container.get_children():
		child.queue_free()
	_table_buttons.clear()
	if _table_logic == null:
		return
	var rows: Array[Dictionary] = _table_logic.generate_rows()
	var header_row: HBoxContainer = HBoxContainer.new()
	_table_container.add_child(header_row)
	var heading: Label = Label.new()
	heading.text = Localization.translate("ui.runes.expression")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(heading)
	var answer_heading: Label = Label.new()
	answer_heading.text = Localization.translate("ui.runes.answer")
	header_row.add_child(answer_heading)
	for row_index: int in range(rows.size()):
		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size.y = 88.0
		_table_container.add_child(row)
		var input_summary: Label = Label.new()
		input_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var assignments: Array[String] = []
		var inputs: Dictionary = rows[row_index]["inputs"] as Dictionary
		for input_id: StringName in _level.truth_table_input_ids:
			var value_key: String = "ui.runes.true" if inputs.get(input_id, false) else "ui.runes.false"
			assignments.append("%s %s: %s" % [Localization.translate("rune.input.name"), String(input_id), Localization.translate(value_key)])
		input_summary.text = Localization.translate("ui.runes.input_summary", {"values": ", ".join(assignments)})
		row.add_child(input_summary)
		var answer: Button = Button.new()
		answer.custom_minimum_size = Vector2(112.0, 88.0)
		answer.button_down.connect(Haptics.vibrate)
		answer.button_down.connect(_animate_button_press.bind(answer))
		answer.button_up.connect(_animate_button_release.bind(answer))
		answer.pressed.connect(_on_truth_table_cell_pressed.bind(row_index))
		row.add_child(answer)
		_table_buttons.append(answer)
		_refresh_table_button(answer, row_index, rows[row_index]["answer"] as int)


func _refresh_table_button(button: Button, row_index: int, answer: int) -> void:
	var expected: int = _level.truth_table_outputs[row_index]
	button.disabled = expected != -1
	if answer == -1:
		button.text = Localization.translate("ui.runes.blank")
	else:
		button.text = Localization.translate("ui.runes.true") if answer == 1 else Localization.translate("ui.runes.false")
	button.tooltip_text = ""


func _rebuild_tray() -> void:
	for child: Node in _tray_container.get_children():
		child.queue_free()
	if _level.mode != RuneLevel.Mode.PLACE_GATES:
		return
	var available: Array[RuneGateType.Type] = _logic.get_remaining_tray()
	for gate_type: RuneGateType.Type in _level.tray:
		var tray_button: Button = Button.new()
		tray_button.custom_minimum_size = Vector2(112.0, 88.0)
		tray_button.text = Localization.translate(_gate_name_key(gate_type))
		tray_button.disabled = not available.has(gate_type)
		if gate_type == _selected_gate:
			tray_button.add_theme_color_override("font_color", Color(0.22, 0.78, 0.62))
		tray_button.button_down.connect(Haptics.vibrate)
		tray_button.button_down.connect(_animate_button_press.bind(tray_button))
		tray_button.button_up.connect(_animate_button_release.bind(tray_button))
		tray_button.pressed.connect(_on_tray_gate_pressed.bind(gate_type))
		_tray_container.add_child(tray_button)


func _update_node_view(node_id: StringName) -> void:
	if not _node_views.has(node_id):
		return
	var node_data: RuneNodeData = _find_node(node_id)
	var node_type: RuneGateType.Type = _logic.get_gate_type(node_id)
	var values: Dictionary[StringName, bool] = _logic.evaluate()
	var value: bool = values.get(node_id, false)
	var can_interact: bool = false
	if _level.mode == RuneLevel.Mode.SET_INPUTS:
		can_interact = node_type == RuneGateType.Type.INPUT and not node_data.locked
	elif _level.mode == RuneLevel.Mode.PLACE_GATES:
		can_interact = node_type == RuneGateType.Type.EMPTY_SLOT or (node_type != RuneGateType.Type.INPUT and node_type != RuneGateType.Type.OUTPUT and not node_data.locked)
	_node_views[node_id].set_node_state(node_id, node_type, value, can_interact)


func _update_wires() -> void:
	if _logic == null:
		return
	_wire_view.set_circuit(_level, _node_positions, _logic.evaluate())


func _update_status() -> void:
	if _level == null:
		return
	var target_key: String = "ui.runes.target_true" if _level.target_value else "ui.runes.target_false"
	if _level.mode == RuneLevel.Mode.TRUTH_TABLE:
		target_key = "ui.runes.complete_table"
	_target_label.text = Localization.translate(target_key)
	_moves_label.text = Localization.translate("ui.runes.moves", {"count": str(_logic.moves if _level.mode != RuneLevel.Mode.TRUTH_TABLE else _table_logic.moves)})
	_hints_label.text = Localization.translate("ui.runes.hints", {"count": str(_discounted_hint_count())})
	_rebuild_tray()


func _on_node_activated(node_id: StringName) -> void:
	if _finished:
		return
	var changed: bool = false
	var node_type: RuneGateType.Type = _logic.get_gate_type(node_id)
	if _level.mode == RuneLevel.Mode.SET_INPUTS and node_type == RuneGateType.Type.INPUT:
		changed = _logic.toggle_input(node_id)
	elif _level.mode == RuneLevel.Mode.PLACE_GATES:
		if node_type == RuneGateType.Type.EMPTY_SLOT and _selected_gate != RuneGateType.Type.EMPTY_SLOT:
			changed = _logic.place_gate(node_id, _selected_gate)
			if changed:
				_selected_gate = RuneGateType.Type.EMPTY_SLOT
		elif node_type != RuneGateType.Type.INPUT and node_type != RuneGateType.Type.OUTPUT:
			changed = _logic.remove_gate(node_id)
	if changed:
		_refresh_circuit()
		_check_solved()
	else:
		_play_sfx(sfx_error)
		_show_popup("ui.runes.invalid_action")


func _on_node_info_requested(node_id: StringName) -> void:
	var node_type: RuneGateType.Type = _logic.get_gate_type(node_id)
	_show_popup(_tooltip_key(node_type))
	match node_type:
		RuneGateType.Type.AND:
			_popup_table_key = "tooltip.rune.and.table"
		RuneGateType.Type.OR:
			_popup_table_key = "tooltip.rune.or.table"
		RuneGateType.Type.NOT:
			_popup_table_key = "tooltip.rune.not.table"
	if not _popup_table_key.is_empty() and _popup_label != null:
		_popup_label.text += "\n\n" + Localization.translate(_popup_table_key)


func _on_tray_gate_pressed(gate_type: RuneGateType.Type) -> void:
	_selected_gate = gate_type if _selected_gate != gate_type else RuneGateType.Type.EMPTY_SLOT
	_rebuild_tray()


func _on_truth_table_cell_pressed(row_index: int) -> void:
	if _finished or _table_logic == null:
		return
	if _table_logic.cycle_answer(row_index):
		Haptics.vibrate()
		_refresh_truth_table_values()
		_update_status()
		_check_solved()


func _refresh_truth_table_values() -> void:
	var rows: Array[Dictionary] = _table_logic.generate_rows()
	for row_index: int in range(_table_buttons.size()):
		_refresh_table_button(_table_buttons[row_index], row_index, rows[row_index]["answer"] as int)


func _on_hint_pressed() -> void:
	if _finished or _level == null:
		return
	var clue_keys: Array[String] = [_level.clue_1_key, _level.clue_2_key, _level.clue_3_key]
	var clue_key: String = clue_keys[mini(_clue_index, clue_keys.size() - 1)]
	_clue_index += 1
	_hints_used += 1
	_popup_key = clue_key
	_popup_table_key = ""
	_popup_params.clear()
	_popup_hint.clear()
	if _level.mode != RuneLevel.Mode.TRUTH_TABLE:
		_popup_hint = _logic.get_hint()
	_update_status()
	_render_popup(_compose_popup_text())


func _describe_hint(suggestion: Dictionary) -> String:
	var kind: String = suggestion.get("kind", "inspect") as String
	if kind == "input":
		var input_value: String = Localization.translate("ui.runes.true") if suggestion.get("value", false) else Localization.translate("ui.runes.false")
		return Localization.translate("ui.runes.hint_input", {"input": String(suggestion.get("node_id", &"")), "value": input_value})
	if kind == "gate":
		return Localization.translate("ui.runes.hint_gate", {"gate": Localization.translate(_gate_name_key(suggestion.get("gate_type", RuneGateType.Type.AND) as RuneGateType.Type))})
	return Localization.translate("ui.runes.hint_inspect")


func _on_guide_pressed() -> void:
	_show_popup("tooltip.rune.guide")


func _on_restart_pressed() -> void:
	if _level != null:
		start_level(_level)


func _on_back_pressed() -> void:
	exit_requested.emit()


func _on_language_changed(_locale: String) -> void:
	_refresh_ui()


func _refresh_circuit() -> void:
	for node_id: StringName in _node_views.keys():
		_update_node_view(node_id)
	_update_wires()
	_update_status()
	var pulse: Tween = create_tween()
	pulse.tween_property(_board, "modulate", Color(1.2, 1.2, 1.2), 0.08)
	pulse.tween_property(_board, "modulate", Color.WHITE, 0.12)


func _check_solved() -> void:
	var solved_now: bool = false
	if _level.mode == RuneLevel.Mode.TRUTH_TABLE:
		solved_now = _table_logic.is_complete() and _table_logic.validate_answers()
	else:
		solved_now = _logic.is_solved()
	if solved_now and not _finished:
		_finish_level()


func _finish_level() -> void:
	_finished = true
	_play_sfx(sfx_solved)
	var move_count: int = _logic.moves if _level.mode != RuneLevel.Mode.TRUTH_TABLE else _table_move_count()
	var stars: int = 3 if move_count <= _level.three_star_moves else (2 if move_count <= _level.two_star_moves else 1)
	var result: PuzzleResult = PuzzleResult.new()
	result.puzzle_id = _level.id
	result.completed = true
	result.stars = stars
	result.moves = move_count
	result.time_seconds = float(Time.get_ticks_msec() - _started_at_msec) / 1000.0
	result.hints_used = _discounted_hint_count()
	GameManager.register_puzzle_result(result)
	level_finished.emit(result)
	_show_result_panel(stars)


func _show_result_panel(stars: int) -> void:
	_result_stars = stars
	for child: Node in _result_layer.get_children():
		child.queue_free()
	_result_layer.visible = true
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.06, 0.08, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_layer.add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(480.0, 340.0)
	panel.position = Vector2(-240.0, -170.0)
	_result_layer.add_child(panel)
	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)
	var title: Label = Label.new()
	title.text = Localization.translate("ui.runes.level_complete")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var stars_label: Label = Label.new()
	stars_label.text = Localization.translate("ui.runes.stars", {"count": str(stars)})
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(stars_label)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	content.add_child(buttons)
	buttons.add_child(_make_button("ui.retry", _on_restart_pressed))
	buttons.add_child(_make_button("ui.runes.next", _on_next_pressed))
	buttons.add_child(_make_button("ui.back", _on_back_pressed))


func _on_next_pressed() -> void:
	var next_number: int = int(_level.id.trim_prefix("runes_")) + 1
	if next_number > 10:
		exit_requested.emit()
		return
	var next_id: String = "runes_%02d" % next_number
	var next_resource: Resource = ResourceLoader.load("res://data/puzzles/runes/%s.tres" % next_id)
	if next_resource is RuneLevel:
		start_level(next_resource as RuneLevel)


func _show_popup(key: String) -> void:
	_popup_key = key
	_popup_table_key = ""
	_popup_params.clear()
	_popup_hint.clear()
	_render_popup(Localization.translate(key))


func _render_popup(text: String) -> void:
	for child: Node in _popup_layer.get_children():
		child.queue_free()
	_popup_layer.visible = true
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.06, 0.08, 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popup_layer.add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(480.0, 240.0)
	panel.position = Vector2(-240.0, -120.0)
	_popup_layer.add_child(panel)
	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)
	_popup_label = Label.new()
	_popup_label.text = text
	_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_popup_label)
	_popup_close_button = _make_button("ui.close", _on_popup_closed)
	content.add_child(_popup_close_button)


func _refresh_popup() -> void:
	if not _popup_layer.visible or _popup_key.is_empty() or _popup_label == null:
		return
	_popup_label.text = _compose_popup_text()
	if _popup_close_button != null:
		_popup_close_button.text = Localization.translate("ui.close")


func _compose_popup_text() -> String:
	var text: String = Localization.translate(_popup_key, _popup_params)
	if not _popup_hint.is_empty():
		text += "\n" + _describe_hint(_popup_hint)
	if not _popup_table_key.is_empty():
		text += "\n\n" + Localization.translate(_popup_table_key)
	return text


func _on_popup_closed() -> void:
	_popup_layer.visible = false
	_popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_key = ""


func _clear_result_panel() -> void:
	_result_layer.visible = false
	for child: Node in _result_layer.get_children():
		child.queue_free()


func _make_button(key: String, handler: Callable) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(112.0, 88.0)
	button.text = Localization.translate(key)
	button.pressed.connect(handler)
	button.button_down.connect(Haptics.vibrate)
	button.button_down.connect(_animate_button_press.bind(button))
	button.button_up.connect(_animate_button_release.bind(button))
	return button


func _animate_button_press(button: Button) -> void:
	var pulse: Tween = button.create_tween()
	pulse.tween_property(button, "scale", Vector2(0.94, 0.94), 0.06)


func _animate_button_release(button: Button) -> void:
	var pulse: Tween = button.create_tween()
	pulse.tween_property(button, "scale", Vector2.ONE, 0.10)


func _apply_asset_slots(node_view: RuneNodeView) -> void:
	if asset_catalog == null:
		return
	node_view.placeholder_rune_and = asset_catalog.placeholder_rune_and
	node_view.placeholder_rune_or = asset_catalog.placeholder_rune_or
	node_view.placeholder_rune_not = asset_catalog.placeholder_rune_not
	node_view.placeholder_rune_input_on = asset_catalog.placeholder_rune_input_on
	node_view.placeholder_rune_input_off = asset_catalog.placeholder_rune_input_off
	node_view.placeholder_rune_output = asset_catalog.placeholder_rune_output
	node_view.sfx_toggle = asset_catalog.sfx_rune_toggle
	node_view.sfx_place = asset_catalog.sfx_rune_place
	node_view.sfx_solved = asset_catalog.sfx_rune_solved
	node_view.sfx_error = asset_catalog.sfx_rune_error


func _find_node(node_id: StringName) -> RuneNodeData:
	for node_data: RuneNodeData in _level.nodes:
		if node_data.id == node_id:
			return node_data
	return null


func _tooltip_key(gate_type: RuneGateType.Type) -> String:
	match gate_type:
		RuneGateType.Type.AND:
			return "tooltip.rune.and"
		RuneGateType.Type.OR:
			return "tooltip.rune.or"
		RuneGateType.Type.NOT:
			return "tooltip.rune.not"
		RuneGateType.Type.OUTPUT:
			return "tooltip.rune.output"
		RuneGateType.Type.EMPTY_SLOT:
			return "tooltip.rune.empty_slot"
	return "tooltip.rune.input"


func _gate_name_key(gate_type: RuneGateType.Type) -> String:
	match gate_type:
		RuneGateType.Type.AND:
			return "rune.and.name"
		RuneGateType.Type.OR:
			return "rune.or.name"
		RuneGateType.Type.NOT:
			return "rune.not.name"
	return "rune.input.name"


func _get_hint_discount() -> int:
	var faction_data: FactionData = GameManager.get_faction_data()
	return faction_data.hint_discount if faction_data != null else 0


func _discounted_hint_count() -> int:
	if _hints_used == 0:
		return 0
	return ceili(float(_hints_used) * float(100 - _hint_discount) / 100.0)


func _table_move_count() -> int:
	return _table_logic.moves if _table_logic != null else 0


func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func moves_label_vertical(status_row: HBoxContainer) -> void:
	status_row.add_child(_moves_label)