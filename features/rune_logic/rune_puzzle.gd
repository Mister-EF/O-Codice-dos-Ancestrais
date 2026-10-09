## Rune-gate puzzle view. Puzzle progress is registered by the scene host.
class_name RunePuzzle
extends Control

signal level_finished(result: PuzzleResult)
signal exit_requested

const NODE_SCENE: PackedScene = preload("res://features/rune_logic/rune_node.tscn")
const PLACEABLE_GATES: Array[RuneNodeDef.RuneGateType] = [
	RuneNodeDef.RuneGateType.AND,
	RuneNodeDef.RuneGateType.OR,
	RuneNodeDef.RuneGateType.NOT,
]

@export var placeholder_rune_and: Texture2D
@export var placeholder_rune_or: Texture2D
@export var placeholder_rune_not: Texture2D
@export var placeholder_rune_input_on: Texture2D
@export var placeholder_rune_input_off: Texture2D
@export var placeholder_rune_output: Texture2D
@export var sfx_toggle: AudioStream
@export var sfx_place: AudioStream
@export var sfx_solved: AudioStream
@export var sfx_error: AudioStream
@export var level_sequence: Array[RuneLevel] = []
@export var asset_catalog: AssetCatalog

var _pending_level: RuneLevel
var _current_level: RuneLevel
var _logic: RuneLogic = RuneLogic.new()
var _truth_logic: TruthTableLogic = TruthTableLogic.new()
var _solution: Dictionary[StringName, Variant] = {}
var _node_views: Dictionary[StringName, RuneNode] = {}
var _wire_canvas: RuneWireCanvas
var _graph_canvas: Control
var _graph_scroll: ScrollContainer
var _truth_rows_container: VBoxContainer
var _table_panel: PanelContainer
var _tray: HBoxContainer
var _title_label: LocalizedLabel
var _intro_label: LocalizedLabel
var _target_label: LocalizedLabel
var _moves_label: LocalizedLabel
var _hints_label: LocalizedLabel
var _clue_label: LocalizedLabel
var _hint_button: LocalizedButton
var _result_panel: Control
var _result_title: LocalizedLabel
var _result_stars: LocalizedLabel
var _result_moves: LocalizedLabel
var _result_hints: LocalizedLabel
var _result_next: LocalizedButton
var _detail_popup: PopupPanel
var _detail_title: LocalizedLabel
var _detail_definition: LocalizedLabel
var _detail_truth: LocalizedLabel
var _audio_player: AudioStreamPlayer
var _selected_gate: RuneNodeDef.RuneGateType = RuneNodeDef.RuneGateType.EMPTY_SLOT
var _highlighted_node_id: StringName = &""
var _highlighted_row: int = -1
var _clue_count: int = 0
var _active_clue_key: String = ""
var _finished: bool = false
var _finishing: bool = false


func _ready() -> void:
	if asset_catalog == null:
		asset_catalog = load("res://data/asset_catalog.tres") as AssetCatalog
	if sfx_toggle == null and asset_catalog != null:
		sfx_toggle = asset_catalog.sfx_ui_click
	_load_default_levels()
	_build_ui()
	EventBus.language_changed.connect(_on_language_changed)
	if _pending_level != null:
		var requested: RuneLevel = _pending_level
		_pending_level = null
		start_level(requested)
	elif not level_sequence.is_empty():
		start_level(level_sequence[0])


func _exit_tree() -> void:
	if EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.disconnect(_on_language_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_graph_canvas):
		call_deferred("_layout_graph")


func start_level(level: RuneLevel) -> void:
	if level == null:
		push_error("RunePuzzle: start_level requires a valid level.")
		return
	if not is_inside_tree():
		_pending_level = level
		return
	_current_level = level
	_logic = RuneLogic.new()
	_truth_logic = TruthTableLogic.new()
	if not _logic.setup(level, GameManager.get_faction_data()):
		return
	if level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE and not _truth_logic.setup(level, GameManager.get_faction_data()):
		return
	_solution = RuneLevelSolver.solve(level)
	if _solution.is_empty():
		push_error("RunePuzzle: level '%s' has no valid solution." % level.id)
		return
	_finished = false
	_finishing = false
	_clue_count = 0
	_active_clue_key = ""
	_selected_gate = RuneNodeDef.RuneGateType.EMPTY_SLOT
	_highlighted_node_id = &""
	_highlighted_row = -1
	_result_panel.visible = false
	_clear_dynamic_content()
	_build_graph()
	_build_truth_table()
	_build_tray()
	_refresh_all()
	call_deferred("_layout_graph")


func _build_ui() -> void:
	var catalog: AssetCatalog = load("res://data/asset_catalog.tres") as AssetCatalog
	var background: TextureRect = TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if catalog != null and catalog.menu_background != null:
		background.texture = catalog.menu_background
	else:
		background.modulate = Color(0.045, 0.055, 0.10)
	add_child(background)
	var safe_area: SafeAreaContainer = SafeAreaContainer.new()
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe_area)
	var margins: MarginContainer = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 14)
	margins.add_theme_constant_override("margin_right", 14)
	margins.add_theme_constant_override("margin_top", 18)
	margins.add_theme_constant_override("margin_bottom", 18)
	safe_area.add_child(margins)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margins.add_child(layout)

	var heading: HBoxContainer = HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	layout.add_child(heading)
	_title_label = LocalizedLabel.new()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.83, 0.48))
	heading.add_child(_title_label)
	var stats: VBoxContainer = VBoxContainer.new()
	heading.add_child(stats)
	_moves_label = LocalizedLabel.new()
	_moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats.add_child(_moves_label)
	_hints_label = LocalizedLabel.new()
	_hints_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats.add_child(_hints_label)
	_intro_label = LocalizedLabel.new()
	_intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro_label.custom_minimum_size = Vector2(0.0, 42.0)
	layout.add_child(_intro_label)
	_target_label = LocalizedLabel.new()
	_target_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_target_label)

	_graph_scroll = ScrollContainer.new()
	_graph_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_graph_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	layout.add_child(_graph_scroll)
	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	_graph_scroll.add_child(content)
	_graph_canvas = Control.new()
	_graph_canvas.custom_minimum_size = Vector2(640.0, 410.0)
	_graph_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_graph_canvas)
	_wire_canvas = RuneWireCanvas.new()
	_wire_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_graph_canvas.add_child(_wire_canvas)
	_table_panel = PanelContainer.new()
	_table_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_table_panel)
	_truth_rows_container = VBoxContainer.new()
	_truth_rows_container.add_theme_constant_override("separation", 4)
	_table_panel.add_child(_truth_rows_container)

	_tray = HBoxContainer.new()
	_tray.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tray.add_theme_constant_override("separation", 8)
	layout.add_child(_tray)
	_clue_label = LocalizedLabel.new()
	_clue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_clue_label.custom_minimum_size = Vector2(0.0, 34.0)
	layout.add_child(_clue_label)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 7)
	layout.add_child(actions)
	_hint_button = LocalizedButton.new()
	_hint_button.translation_key = "ui.runes.hint"
	_hint_button.custom_minimum_size = Vector2(0.0, 56.0)
	_hint_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_button.pressed.connect(_on_hint_pressed)
	actions.add_child(_hint_button)
	var restart_button: LocalizedButton = LocalizedButton.new()
	restart_button.translation_key = "ui.runes.restart"
	restart_button.custom_minimum_size = Vector2(0.0, 56.0)
	restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_button.pressed.connect(_on_restart_pressed)
	actions.add_child(restart_button)
	var back_button: LocalizedButton = LocalizedButton.new()
	back_button.translation_key = "ui.runes.back"
	back_button.custom_minimum_size = Vector2(0.0, 56.0)
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(_on_back_pressed)
	actions.add_child(back_button)

	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "SFX"
	add_child(_audio_player)
	_build_detail_popup()
	_build_result_panel()


func _build_graph() -> void:
	var values: Dictionary[StringName, bool] = _logic.evaluate()
	for definition: RuneNodeDef in _current_level.nodes:
		var node_view: RuneNode = NODE_SCENE.instantiate() as RuneNode
		node_view.placeholder_rune_and = placeholder_rune_and
		node_view.placeholder_rune_or = placeholder_rune_or
		node_view.placeholder_rune_not = placeholder_rune_not
		node_view.placeholder_rune_input_on = placeholder_rune_input_on
		node_view.placeholder_rune_input_off = placeholder_rune_input_off
		node_view.placeholder_rune_output = placeholder_rune_output
		var gate_type: RuneNodeDef.RuneGateType = _logic.placed_gates.get(
			definition.id,
			definition.gate_type
		)
		var filled: bool = definition.gate_type != RuneNodeDef.RuneGateType.EMPTY_SLOT
		node_view.configure(definition, values.get(definition.id, false), gate_type, filled)
		node_view.node_activated.connect(_on_node_activated)
		node_view.info_requested.connect(_show_gate_info)
		_graph_canvas.add_child(node_view)
		_node_views[definition.id] = node_view
	_table_panel.visible = _current_level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE
	_tray.visible = _current_level.mode == RuneLevel.PuzzleMode.PLACE_GATES or _current_level.mode == RuneLevel.PuzzleMode.MIXED


func _build_truth_table() -> void:
	if _current_level.mode != RuneLevel.PuzzleMode.TRUTH_TABLE:
		return
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	_truth_rows_container.add_child(header)
	for input_id: StringName in _truth_logic.input_ids:
		var heading: LocalizedLabel = LocalizedLabel.new()
		heading.set_localized("ui.runes.input_column", {
			"index": _truth_logic.input_ids.find(input_id) + 1,
		})
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(heading)
	var output_heading: LocalizedLabel = LocalizedLabel.new()
	output_heading.translation_key = "rune.output.name"
	output_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	output_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(output_heading)

	for row_index: int in range(_truth_logic.rows.size()):
		var row_container: HBoxContainer = HBoxContainer.new()
		row_container.add_theme_constant_override("separation", 4)
		_truth_rows_container.add_child(row_container)
		var row: Dictionary = _truth_logic.rows[row_index]
		var row_inputs: Array = row["inputs"]
		for column: int in range(row_inputs.size()):
			var input_label: LocalizedLabel = LocalizedLabel.new()
			input_label.set_localized("ui.runes.value_true" if bool(row_inputs[column]) else "ui.runes.value_false")
			input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			input_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row_container.add_child(input_label)
		var answer_selector: OptionButton = OptionButton.new()
		answer_selector.custom_minimum_size = Vector2(0.0, 48.0)
		answer_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		answer_selector.add_item(Localization.translate("ui.runes.answer_blank"), -1)
		answer_selector.add_item(Localization.translate("ui.runes.value_true"), 1)
		answer_selector.add_item(Localization.translate("ui.runes.value_false"), 0)
		answer_selector.set_meta("truth_row", row_index)
		answer_selector.item_selected.connect(
			_on_truth_answer_selected.bind(row_index, answer_selector)
		)
		row_container.add_child(answer_selector)
		_refresh_truth_answer(row_index, answer_selector)


func _build_tray() -> void:
	for child: Node in _tray.get_children():
		child.queue_free()
	if not _tray.visible:
		return
	var unique_gates: Dictionary[int, bool] = {}
	for gate: RuneNodeDef.RuneGateType in _current_level.tray:
		if unique_gates.has(gate):
			continue
		unique_gates[gate] = true
		var button: LocalizedButton = LocalizedButton.new()
		button.custom_minimum_size = Vector2(88.0, 64.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("gate_type", int(gate))
		button.pressed.connect(_on_tray_gate_pressed.bind(gate, button))
		_tray.add_child(button)
		_refresh_tray_button(button, gate)


func _build_detail_popup() -> void:
	_detail_popup = PopupPanel.new()
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(390.0, 260.0)
	_detail_popup.add_child(panel)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	_detail_title = LocalizedLabel.new()
	_detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_title.add_theme_font_size_override("font_size", 24)
	content.add_child(_detail_title)
	_detail_definition = LocalizedLabel.new()
	_detail_definition.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_detail_definition)
	_detail_truth = LocalizedLabel.new()
	_detail_truth.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_detail_truth)
	add_child(_detail_popup)


func _build_result_panel() -> void:
	_result_panel = Control.new()
	_result_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.07, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_panel.add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_panel.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(480.0, 340.0)
	center.add_child(panel)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	_result_title = LocalizedLabel.new()
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.add_theme_font_size_override("font_size", 28)
	content.add_child(_result_title)
	_result_stars = LocalizedLabel.new()
	_result_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_result_stars)
	_result_moves = LocalizedLabel.new()
	content.add_child(_result_moves)
	_result_hints = LocalizedLabel.new()
	content.add_child(_result_hints)
	var retry: LocalizedButton = LocalizedButton.new()
	retry.translation_key = "ui.runes.retry"
	retry.pressed.connect(_on_restart_pressed)
	content.add_child(retry)
	_result_next = LocalizedButton.new()
	_result_next.translation_key = "ui.runes.next"
	_result_next.pressed.connect(_on_next_pressed)
	content.add_child(_result_next)
	var back: LocalizedButton = LocalizedButton.new()
	back.translation_key = "ui.runes.back"
	back.pressed.connect(_on_back_pressed)
	content.add_child(back)
	_result_panel.visible = false
	add_child(_result_panel)


func _clear_dynamic_content() -> void:
	for id: StringName in _node_views:
		_node_views[id].queue_free()
	_node_views.clear()
	for child: Node in _truth_rows_container.get_children():
		child.queue_free()
	_selected_gate = RuneNodeDef.RuneGateType.EMPTY_SLOT


func _layout_graph() -> void:
	if _current_level == null or not is_instance_valid(_graph_canvas):
		return
	var node_size: Vector2 = Vector2(116.0, 108.0)
	var usable: Vector2 = Vector2(
		maxf(node_size.x, _graph_canvas.size.x - node_size.x),
		maxf(node_size.y, _graph_canvas.size.y - node_size.y)
	)
	for definition: RuneNodeDef in _current_level.nodes:
		if not _node_views.has(definition.id):
			continue
		var view: RuneNode = _node_views[definition.id]
		view.custom_minimum_size = node_size
		view.size = node_size
		view.position = Vector2(
			clampf(definition.layout_position.x, 0.0, 1.0) * usable.x,
			clampf(definition.layout_position.y, 0.0, 1.0) * usable.y
		)
	_wire_canvas.configure(_current_level, _node_views, _logic.evaluate())


func _refresh_all() -> void:
	if _current_level == null:
		return
	_title_label.set_localized(_current_level.title_key)
	_intro_label.set_localized(_current_level.intro_key)
	_target_label.set_localized(
		"ui.runes.target_true" if _current_level.target_value else "ui.runes.target_false"
	)
	_refresh_moves()
	_refresh_hint_count()
	_refresh_clue()
	_refresh_nodes()
	_refresh_wires()
	_refresh_hint_button()
	_refresh_truth_answers()
	for child: Node in _tray.get_children():
		var button: LocalizedButton = child as LocalizedButton
		if button != null:
			_refresh_tray_button(button, int(button.get_meta("gate_type")) as RuneNodeDef.RuneGateType)
	if _detail_popup.visible:
		_refresh_gate_info()


func _refresh_nodes() -> void:
	var values: Dictionary[StringName, bool] = _logic.evaluate()
	for definition: RuneNodeDef in _current_level.nodes:
		if not _node_views.has(definition.id):
			continue
		var view: RuneNode = _node_views[definition.id]
		var gate_type: RuneNodeDef.RuneGateType = _logic.placed_gates.get(definition.id, definition.gate_type)
		var filled: bool = definition.gate_type != RuneNodeDef.RuneGateType.EMPTY_SLOT or _logic.placed_gates.has(definition.id)
		view.set_state(values.get(definition.id, false), gate_type, filled)
		view.set_selected(definition.id == _selected_slot_id())
		view.set_highlighted(definition.id == _highlighted_node_id)


func _refresh_wires() -> void:
	if is_instance_valid(_wire_canvas):
		_wire_canvas.configure(_current_level, _node_views, _logic.evaluate())


func _refresh_truth_answer(row_index: int, selector: OptionButton) -> void:
	if not _truth_logic.answers.has(row_index):
		return
	selector.set_item_text(0, Localization.translate("ui.runes.answer_blank"))
	selector.set_item_text(1, Localization.translate("ui.runes.value_true"))
	selector.set_item_text(2, Localization.translate("ui.runes.value_false"))
	var is_missing: bool = _current_level.truth_table_missing_rows.has(row_index)
	selector.disabled = not is_missing
	selector.modulate = Color(1.0, 0.87, 0.35) if row_index == _highlighted_row else Color.WHITE
	if not is_missing:
		var row: Dictionary = _truth_logic.rows[row_index]
		selector.select(1 if bool(row["expected"]) else 2)
	elif not _truth_logic.answered_rows.has(row_index):
		selector.select(0)
	else:
		selector.select(1 if bool(_truth_logic.answers[row_index]) else 2)


func _refresh_moves() -> void:
	var move_count: int = _truth_logic.moves if _current_level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE else _logic.moves
	_moves_label.set_localized("ui.runes.moves", {
		"moves": move_count,
		"par": _current_level.par_moves,
	})


func _refresh_hint_count() -> void:
	var count: int = _truth_logic.hints_used if _current_level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE else _logic.hints_used
	_hints_label.set_localized("ui.runes.hints_used", {"count": count})


func _refresh_clue() -> void:
	if _active_clue_key.is_empty():
		_clue_label.set_localized("ui.runes.clue_empty")
	else:
		_clue_label.set_localized("ui.runes.clue_message", {
			"count": _clue_count,
			"clue": Localization.translate(_active_clue_key),
		})


func _refresh_hint_button() -> void:
	if not is_instance_valid(_hint_button):
		return
	var hint_exists: bool = _truth_logic.get_hint() >= 0 if _current_level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE else _logic.get_hint(_solution) != &""
	_hint_button.disabled = _finished or _finishing or _clue_count >= 3 or not hint_exists
	_hint_button.set_localized("ui.runes.hint", {"count": _clue_count})


func _refresh_tray_button(button: LocalizedButton, gate_type: RuneNodeDef.RuneGateType) -> void:
	var count: int = int(_logic.tray_counts.get(gate_type, 0))
	var gate_key: String = _gate_name_key(gate_type)
	button.set_localized("ui.runes.tray_gate", {
		"gate": Localization.translate(gate_key),
		"count": count,
	})
	button.disabled = count <= 0 or _finished or _finishing
	button.modulate = Color(1.0, 0.84, 0.37) if gate_type == _selected_gate else Color.WHITE


func _on_node_activated(node_id: StringName) -> void:
	if _finished or _finishing or not _logic.nodes.has(node_id):
		return
	var definition: RuneNodeDef = _logic.nodes[node_id]
	if definition.gate_type == RuneNodeDef.RuneGateType.INPUT:
		if _current_level.mode != RuneLevel.PuzzleMode.SET_INPUTS and _current_level.mode != RuneLevel.PuzzleMode.MIXED:
			return
		if _logic.toggle_input(node_id):
			_play_sound(sfx_toggle)
			_after_change()
	elif definition.gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT:
		if _logic.placed_gates.has(node_id):
			if _logic.remove_gate(node_id):
				_selected_gate = RuneNodeDef.RuneGateType.EMPTY_SLOT
				_play_sound(sfx_place)
				_after_change()
		elif _selected_gate != RuneNodeDef.RuneGateType.EMPTY_SLOT:
			if _logic.place_gate(node_id, _selected_gate):
				_play_sound(sfx_place)
				if int(_logic.tray_counts.get(_selected_gate, 0)) <= 0:
					_selected_gate = RuneNodeDef.RuneGateType.EMPTY_SLOT
				_after_change()
			else:
				_play_sound(sfx_error)


func _on_tray_gate_pressed(gate_type: RuneNodeDef.RuneGateType, _button: LocalizedButton) -> void:
	if _finished or _finishing or int(_logic.tray_counts.get(gate_type, 0)) <= 0:
		return
	_selected_gate = gate_type
	_refresh_nodes()
	_refresh_tray_buttons()


func _on_truth_answer_selected(item_index: int, row_index: int, selector: OptionButton) -> void:
	if _finished or _finishing:
		return
	var answer_id: int = selector.get_item_id(item_index)
	if answer_id < 0:
		_refresh_truth_answers()
		return
	if not _truth_logic.set_answer(row_index, answer_id == 1):
		return
	_refresh_truth_answers()
	_refresh_moves()
	_refresh_hint_count()
	_check_solved()


func _after_change() -> void:
	_refresh_nodes()
	_refresh_wires()
	_refresh_moves()
	_refresh_hint_count()
	_refresh_tray_buttons()
	_refresh_hint_button()
	_check_solved()


func _check_solved() -> void:
	var solved: bool = _truth_logic.is_solved() if _current_level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE else _logic.is_solved()
	if solved and not _finished and not _finishing:
		_finishing = true
		_play_sound(sfx_solved)
		var tween: Tween = create_tween()
		tween.tween_interval(0.35)
		tween.tween_callback(func() -> void: _finish_level())


func _on_hint_pressed() -> void:
	if _finished or _finishing or _clue_count >= 3:
		return
	var next_hint: StringName = &""
	var truth_hint: int = -1
	var registered: bool
	if _current_level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE:
		truth_hint = _truth_logic.get_hint()
		registered = _truth_logic.register_hint()
		_highlighted_row = truth_hint
	else:
		next_hint = _logic.get_hint(_solution)
		registered = _logic.register_hint()
		_highlighted_node_id = next_hint
	if not registered:
		return
	_clue_count += 1
	match _clue_count:
		1:
			_active_clue_key = _current_level.clue_1_key
		2:
			_active_clue_key = _current_level.clue_2_key
		_:
			_active_clue_key = _current_level.clue_3_key
	_play_sound(sfx_toggle)
	_refresh_clue()
	_refresh_nodes()
	_refresh_truth_answers()
	_refresh_hint_count()
	_refresh_hint_button()


func _refresh_truth_answers() -> void:
	for child: Node in _truth_rows_container.get_children():
		if child is not HBoxContainer:
			continue
		var row_container: HBoxContainer = child as HBoxContainer
		for answer_node: Node in row_container.get_children():
			var selector: OptionButton = answer_node as OptionButton
			if selector != null and selector.has_meta("truth_row"):
				var row_index: int = int(selector.get_meta("truth_row"))
				_refresh_truth_answer(row_index, selector)


func _refresh_tray_buttons() -> void:
	for child: Node in _tray.get_children():
		var button: LocalizedButton = child as LocalizedButton
		if button != null:
			_refresh_tray_button(button, int(button.get_meta("gate_type")) as RuneNodeDef.RuneGateType)


func _selected_slot_id() -> StringName:
	for id: StringName in _logic.nodes:
		if _logic.nodes[id].gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT and not _logic.placed_gates.has(id):
			return id if _selected_gate != RuneNodeDef.RuneGateType.EMPTY_SLOT else &""
	return &""


func _show_gate_info(node_id: StringName) -> void:
	if not _logic.nodes.has(node_id):
		return
	_detail_popup.set_meta("node_id", node_id)
	_refresh_gate_info()
	_detail_popup.popup_centered(Vector2i(420, 280))


func _refresh_gate_info() -> void:
	if not _detail_popup.has_meta("node_id") or not is_instance_valid(_detail_title):
		return
	var node_id: StringName = _detail_popup.get_meta("node_id") as StringName
	if not _logic.nodes.has(node_id):
		return
	var definition: RuneNodeDef = _logic.nodes[node_id]
	var type: RuneNodeDef.RuneGateType = _logic.placed_gates.get(node_id, definition.gate_type)
	var key: String = _gate_name_key(type)
	_detail_title.set_localized(key)
	_detail_definition.set_localized(key.replace(".name", ".definition"))
	if type == RuneNodeDef.RuneGateType.AND or type == RuneNodeDef.RuneGateType.OR or type == RuneNodeDef.RuneGateType.NOT:
		_detail_truth.set_localized(key.replace(".name", ".truth"))
	else:
		_detail_truth.set_localized("rune.gate.no_table")


func _finish_level() -> void:
	if _finished or _current_level == null:
		return
	_finished = true
	_finishing = false
	var result: PuzzleResult = PuzzleResult.new()
	result.puzzle_id = _current_level.id
	result.completed = true
	result.stars = _truth_logic.calculate_stars() if _current_level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE else _logic.calculate_stars()
	result.moves = _truth_logic.moves if _current_level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE else _logic.moves
	result.hints_used = _truth_logic.hints_used if _current_level.mode == RuneLevel.PuzzleMode.TRUTH_TABLE else _logic.hints_used
	_result_title.set_localized("ui.runes.level_complete")
	_result_stars.set_localized("ui.runes.stars", {
		"stars": "★".repeat(result.stars) + "☆".repeat(3 - result.stars),
	})
	_result_moves.set_localized("ui.runes.result_moves", {
		"moves": result.moves,
		"par": _current_level.par_moves,
	})
	_result_hints.set_localized("ui.runes.result_hints", {"count": result.hints_used})
	_result_next.visible = _next_level() != null
	_result_panel.visible = true
	_refresh_hint_button()
	level_finished.emit(result)


func _on_restart_pressed() -> void:
	if _current_level != null:
		start_level(_current_level)


func _on_next_pressed() -> void:
	var next_level: RuneLevel = _next_level()
	if next_level != null:
		start_level(next_level)
	else:
		exit_requested.emit()


func _on_back_pressed() -> void:
	exit_requested.emit()


func _next_level() -> RuneLevel:
	if _current_level == null:
		return null
	for index: int in range(level_sequence.size()):
		if level_sequence[index].id == _current_level.id and index + 1 < level_sequence.size():
			return level_sequence[index + 1]
	return null


func _on_language_changed(_locale: String) -> void:
	_refresh_all()


func _load_default_levels() -> void:
	if not level_sequence.is_empty():
		return
	for index: int in range(1, 11):
		var path: String = "res://data/puzzles/runes/runes_%02d.tres" % index
		var level: RuneLevel = load(path) as RuneLevel
		if level == null:
			push_error("RunePuzzle: unable to load level '%s'." % path)
			return
		level_sequence.append(level)


func _gate_name_key(type: RuneNodeDef.RuneGateType) -> String:
	match type:
		RuneNodeDef.RuneGateType.INPUT:
			return "rune.input.name"
		RuneNodeDef.RuneGateType.AND:
			return "rune.and.name"
		RuneNodeDef.RuneGateType.OR:
			return "rune.or.name"
		RuneNodeDef.RuneGateType.NOT:
			return "rune.not.name"
		RuneNodeDef.RuneGateType.OUTPUT:
			return "rune.output.name"
		_:
			return "rune.slot.name"


func _play_sound(stream: AudioStream) -> void:
	if stream == null or not is_instance_valid(_audio_player):
		return
	_audio_player.stream = stream
	_audio_player.play()
