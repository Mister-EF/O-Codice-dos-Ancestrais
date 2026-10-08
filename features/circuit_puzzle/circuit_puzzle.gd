## Circuit puzzle view. Puzzle progress is registered by its scene host.
class_name CircuitPuzzle
extends Control

signal level_finished(result: PuzzleResult)
signal exit_requested

const TILE_SCENE: PackedScene = preload("res://features/circuit_puzzle/circuit_tile.tscn")

@export var placeholder_tile_texture: Texture2D
@export var placeholder_source_texture: Texture2D
@export var placeholder_target_texture: Texture2D
@export var placeholder_blocker_texture: Texture2D
@export var sfx_rotate: AudioStream
@export var sfx_powered: AudioStream
@export var sfx_solved: AudioStream
@export var level_sequence: Array[CircuitLevel] = []
@export var asset_catalog: AssetCatalog

var _pending_level: CircuitLevel
var _current_level: CircuitLevel
var _logic: CircuitLogic = CircuitLogic.new()
var _tiles: Dictionary[Vector2i, CircuitTile] = {}
var _title_label: LocalizedLabel
var _intro_label: LocalizedLabel
var _moves_label: LocalizedLabel
var _time_label: LocalizedLabel
var _hint_button: LocalizedButton
var _grid_holder: CenterContainer
var _grid: GridContainer
var _result_panel: Control
var _result_title: LocalizedLabel
var _result_stars: LocalizedLabel
var _result_moves: LocalizedLabel
var _result_time: LocalizedLabel
var _result_next: LocalizedButton
var _detail_popup: PopupPanel
var _detail_title: LocalizedLabel
var _detail_definition: LocalizedLabel
var _detail_hint: LocalizedLabel
var _detail_key: String = ""
var _audio_player: AudioStreamPlayer
var _elapsed_seconds: float = 0.0
var _timer_started: bool = false
var _finished: bool = false
var _finishing: bool = false
var _highlighted_cell: Vector2i = CircuitLogic.INVALID_CELL


func _ready() -> void:
	if asset_catalog == null:
		asset_catalog = load("res://data/asset_catalog.tres") as AssetCatalog
	if sfx_rotate == null and asset_catalog != null:
		sfx_rotate = asset_catalog.sfx_ui_click
	_load_default_levels()
	_build_ui()
	EventBus.language_changed.connect(_on_language_changed)
	if _pending_level != null:
		var requested_level: CircuitLevel = _pending_level
		_pending_level = null
		start_level(requested_level)
	elif not level_sequence.is_empty():
		start_level(level_sequence[0])


func _exit_tree() -> void:
	if EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.disconnect(_on_language_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_grid_holder):
		call_deferred("_fit_tiles")


func start_level(level: CircuitLevel) -> void:
	if level == null:
		push_error("CircuitPuzzle: start_level requires a valid level.")
		return
	if not is_inside_tree():
		_pending_level = level
		return
	_current_level = level
	if not _logic.setup(level, GameManager.get_faction_data()):
		return
	_elapsed_seconds = 0.0
	_timer_started = false
	_finished = false
	_finishing = false
	_highlighted_cell = CircuitLogic.INVALID_CELL
	_result_panel.visible = false
	for cell: Vector2i in _tiles:
		var tile: CircuitTile = _tiles[cell]
		tile.queue_free()
	_tiles.clear()
	_grid.columns = level.grid_columns
	for y: int in range(level.grid_rows):
		for x: int in range(level.grid_columns):
			var cell: Vector2i = Vector2i(x, y)
			var definition: CircuitTileDef = _logic.tiles.get(cell) as CircuitTileDef
			var tile: CircuitTile = TILE_SCENE.instantiate() as CircuitTile
			tile.placeholder_tile_texture = placeholder_tile_texture
			tile.placeholder_source_texture = placeholder_source_texture
			tile.placeholder_target_texture = placeholder_target_texture
			tile.placeholder_blocker_texture = placeholder_blocker_texture
			tile.custom_minimum_size = Vector2(88.0, 88.0)
			tile.configure(definition, int(_logic.rotations.get(cell, 0)))
			tile.rotation_requested.connect(_on_tile_rotation_requested.bind(cell))
			tile.detail_requested.connect(_show_node_detail)
			_grid.add_child(tile)
			_tiles[cell] = tile
	_refresh_header()
	_refresh_hint_button()
	_sync_powered(false)
	call_deferred("_fit_tiles")


func _process(delta: float) -> void:
	if _finished or _finishing or not _timer_started:
		return
	_elapsed_seconds += delta
	_refresh_time_label()
	if _current_level.time_limit_seconds > 0.0 and _elapsed_seconds >= _current_level.time_limit_seconds:
		_finish_level(false)


func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.045, 0.06, 0.105)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var safe_area: SafeAreaContainer = SafeAreaContainer.new()
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe_area)
	var margins: MarginContainer = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 22)
	margins.add_theme_constant_override("margin_right", 22)
	margins.add_theme_constant_override("margin_top", 28)
	margins.add_theme_constant_override("margin_bottom", 28)
	safe_area.add_child(margins)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margins.add_child(layout)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	layout.add_child(header)
	_title_label = LocalizedLabel.new()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 27)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.48))
	header.add_child(_title_label)
	var stats: VBoxContainer = VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_SHRINK_END
	header.add_child(stats)
	_moves_label = LocalizedLabel.new()
	_moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats.add_child(_moves_label)
	_time_label = LocalizedLabel.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats.add_child(_time_label)
	_intro_label = LocalizedLabel.new()
	_intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro_label.custom_minimum_size = Vector2(0.0, 48.0)
	layout.add_child(_intro_label)

	_grid_holder = CenterContainer.new()
	_grid_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_grid_holder)
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_grid_holder.add_child(_grid)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	layout.add_child(footer)
	_hint_button = LocalizedButton.new()
	_hint_button.translation_key = "ui.circuit.hint"
	_hint_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_button.custom_minimum_size = Vector2(0.0, 54.0)
	_hint_button.pressed.connect(_on_hint_pressed)
	footer.add_child(_hint_button)
	var restart_button: LocalizedButton = LocalizedButton.new()
	restart_button.translation_key = "ui.circuit.restart"
	restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_button.custom_minimum_size = Vector2(0.0, 54.0)
	restart_button.pressed.connect(_on_restart_pressed)
	footer.add_child(restart_button)
	var back_button: LocalizedButton = LocalizedButton.new()
	back_button.translation_key = "ui.circuit.back"
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.custom_minimum_size = Vector2(0.0, 54.0)
	back_button.pressed.connect(_on_back_pressed)
	footer.add_child(back_button)

	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "SFX"
	add_child(_audio_player)
	_build_detail_popup()
	_build_result_panel()


func _build_detail_popup() -> void:
	_detail_popup = PopupPanel.new()
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400.0, 250.0)
	_detail_popup.add_child(panel)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	_detail_title = LocalizedLabel.new()
	_detail_title.add_theme_font_size_override("font_size", 23)
	content.add_child(_detail_title)
	_detail_definition = LocalizedLabel.new()
	_detail_definition.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_detail_definition)
	_detail_hint = LocalizedLabel.new()
	_detail_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_detail_hint)
	add_child(_detail_popup)


func _build_result_panel() -> void:
	_result_panel = Control.new()
	_result_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.07, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_panel.add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_panel.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500.0, 360.0)
	center.add_child(panel)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	_result_title = LocalizedLabel.new()
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.add_theme_font_size_override("font_size", 29)
	content.add_child(_result_title)
	_result_stars = LocalizedLabel.new()
	_result_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_result_stars)
	_result_moves = LocalizedLabel.new()
	content.add_child(_result_moves)
	_result_time = LocalizedLabel.new()
	content.add_child(_result_time)
	var retry: LocalizedButton = LocalizedButton.new()
	retry.translation_key = "ui.circuit.retry"
	retry.pressed.connect(_on_restart_pressed)
	content.add_child(retry)
	_result_next = LocalizedButton.new()
	_result_next.translation_key = "ui.circuit.next"
	_result_next.pressed.connect(_on_next_pressed)
	content.add_child(_result_next)
	var back: LocalizedButton = LocalizedButton.new()
	back.translation_key = "ui.circuit.back"
	back.pressed.connect(_on_back_pressed)
	content.add_child(back)
	_result_panel.visible = false
	add_child(_result_panel)


func _refresh_header() -> void:
	if _current_level == null or not is_instance_valid(_title_label):
		return
	_title_label.set_localized(_current_level.title_key)
	_intro_label.set_localized(_current_level.intro_key)
	_refresh_move_label()
	_refresh_time_label()


func _refresh_move_label() -> void:
	if _current_level == null or not is_instance_valid(_moves_label):
		return
	_moves_label.set_localized("ui.circuit.moves", {
		"moves": _logic.moves,
		"par": _current_level.par_moves,
	})


func _refresh_time_label() -> void:
	if _current_level == null or not is_instance_valid(_time_label):
		return
	if _current_level.time_limit_seconds <= 0.0:
		_time_label.set_localized("ui.circuit.no_timer")
	else:
		_time_label.set_localized("ui.circuit.time", {"time": _format_time(_elapsed_seconds)})


func _refresh_hint_button() -> void:
	if is_instance_valid(_hint_button):
		_hint_button.disabled = _finished or _finishing or _logic.get_hint() == CircuitLogic.INVALID_CELL


func _fit_tiles() -> void:
	if not is_instance_valid(_grid_holder) or _current_level == null:
		return
	var gap: float = 8.0
	var available_width: float = maxf(0.0, _grid_holder.size.x - gap * float(_current_level.grid_columns - 1))
	var available_height: float = maxf(0.0, _grid_holder.size.y - gap * float(_current_level.grid_rows - 1))
	var side: float = floorf(minf(
		available_width / float(_current_level.grid_columns),
		available_height / float(_current_level.grid_rows)
	))
	side = maxf(88.0, minf(116.0, side))
	for cell: Vector2i in _tiles:
		var tile: CircuitTile = _tiles[cell]
		tile.custom_minimum_size = Vector2(side, side)
		tile.size = Vector2(side, side)


func _sync_powered(stagger: bool) -> void:
	var powered: Dictionary[Vector2i, bool] = _logic.compute_powered()
	if stagger:
		for cell: Vector2i in _tiles:
			_tiles[cell].set_powered(false)
		var order: Array[Vector2i] = _logic.get_powered_order()
		for index: int in range(order.size()):
			var cell: Vector2i = order[index]
			var tween: Tween = create_tween()
			tween.tween_interval(float(index) * 0.055)
			tween.tween_callback(_set_cell_powered.bind(cell))
		if sfx_powered != null:
			_play_sound(sfx_powered)
		return
	for cell: Vector2i in _tiles:
		_tiles[cell].set_powered(powered.has(cell))


func _on_tile_rotation_requested(cell: Vector2i) -> void:
	if _finished or _finishing or not _logic.tiles.has(cell):
		return
	var definition: CircuitTileDef = _logic.tiles[cell]
	if definition.locked:
		_tiles[cell].shake_locked()
		return
	_timer_started = true
	_logic.rotate_tile(cell)
	_tiles[cell].set_rotation_index(int(_logic.rotations.get(cell, 0)))
	_play_sound(sfx_rotate)
	_highlight_cell(CircuitLogic.INVALID_CELL)
	_refresh_move_label()
	_sync_powered(false)
	_refresh_hint_button()
	if _logic.is_solved():
		_finishing = true
		_refresh_hint_button()
		_sync_powered(true)
		if sfx_solved != null:
			_play_sound(sfx_solved)
		var finish_tween: Tween = create_tween()
		finish_tween.tween_interval(0.75)
		finish_tween.tween_callback(func() -> void: _finish_level(true))


func _on_hint_pressed() -> void:
	if _finished or _finishing:
		return
	var hint_cell: Vector2i = _logic.get_hint()
	if hint_cell == CircuitLogic.INVALID_CELL:
		return
	if not _logic.register_hint():
		return
	_timer_started = true
	_highlight_cell(hint_cell)
	_refresh_move_label()
	_refresh_hint_button()


func _highlight_cell(cell: Vector2i) -> void:
	if _highlighted_cell != CircuitLogic.INVALID_CELL and _tiles.has(_highlighted_cell):
		_tiles[_highlighted_cell].set_highlighted(false)
	_highlighted_cell = cell
	if cell != CircuitLogic.INVALID_CELL and _tiles.has(cell):
		_tiles[cell].set_highlighted(true)


func _set_cell_powered(cell: Vector2i) -> void:
	if _tiles.has(cell):
		_tiles[cell].set_powered(true)


func _show_node_detail(label_key: String) -> void:
	_detail_key = label_key
	_refresh_detail()
	_detail_popup.popup_centered(Vector2i(420, 270))


func _refresh_detail() -> void:
	if _detail_key.is_empty() or not is_instance_valid(_detail_title):
		return
	_detail_title.set_localized(_detail_key + ".name")
	_detail_definition.set_localized(_detail_key + ".definition")
	_detail_hint.set_localized(_detail_key + ".hint")


func _finish_level(completed: bool) -> void:
	if _finished or _current_level == null:
		return
	_finished = true
	_finishing = false
	var result: PuzzleResult = PuzzleResult.new()
	result.puzzle_id = _current_level.id
	result.completed = completed
	result.stars = _logic.calculate_stars() if completed else 0
	result.moves = _logic.moves
	result.time_seconds = _elapsed_seconds
	result.hints_used = _logic.hints_used
	var result_key: String = "ui.circuit.level_complete" if completed else "ui.circuit.level_failed"
	_result_title.set_localized(result_key)
	var star_display: String = "★".repeat(result.stars) + "☆".repeat(3 - result.stars)
	_result_stars.set_localized("ui.circuit.stars", {"stars": star_display})
	_result_moves.set_localized("ui.circuit.result_moves", {
		"moves": result.moves,
		"par": _current_level.par_moves,
	})
	_result_time.set_localized("ui.circuit.result_time", {"time": _format_time(result.time_seconds)})
	_result_next.visible = completed and _next_level() != null
	_result_panel.visible = true
	_refresh_hint_button()
	level_finished.emit(result)


func _on_restart_pressed() -> void:
	if _current_level != null:
		start_level(_current_level)


func _on_next_pressed() -> void:
	var next_level: CircuitLevel = _next_level()
	if next_level != null:
		start_level(next_level)
	else:
		exit_requested.emit()


func _on_back_pressed() -> void:
	exit_requested.emit()


func _next_level() -> CircuitLevel:
	if _current_level == null:
		return null
	for index: int in range(level_sequence.size()):
		if level_sequence[index].id == _current_level.id and index + 1 < level_sequence.size():
			return level_sequence[index + 1]
	return null


func _on_language_changed(_locale: String) -> void:
	_refresh_header()
	_refresh_detail()


func _play_sound(stream: AudioStream) -> void:
	if stream == null or not is_instance_valid(_audio_player):
		return
	_audio_player.stream = stream
	_audio_player.play()


func _format_time(seconds: float) -> String:
	var total_seconds: int = floori(seconds)
	return "%02d:%02d" % [floori(float(total_seconds) / 60.0), total_seconds % 60]


func _load_default_levels() -> void:
	if not level_sequence.is_empty():
		return
	for index: int in range(1, 9):
		var path: String = "res://data/puzzles/circuit/circuit_%02d.tres" % index
		var level: CircuitLevel = load(path) as CircuitLevel
		if level == null:
			push_error("CircuitPuzzle: unable to load authored level '%s'." % path)
			return
		level_sequence.append(level)
