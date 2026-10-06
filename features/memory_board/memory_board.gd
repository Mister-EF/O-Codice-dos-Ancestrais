## Memory puzzle scene. Puzzle progress is registered by the scene host.
class_name MemoryBoard
extends Control

signal level_finished(result: PuzzleResult)
signal exit_requested

const CARD_SCENE: PackedScene = preload("res://features/memory_board/memory_card.tscn")
const RESULT_PANEL_SCENE: PackedScene = preload("res://features/memory_board/memory_result_panel.tscn")

@export var placeholder_card_back: Texture2D
@export var placeholder_card_front: Texture2D
@export var sfx_flip: AudioStream
@export var sfx_match: AudioStream
@export var sfx_mismatch: AudioStream
@export var sfx_win: AudioStream
@export var level_sequence: Array[MemoryBoardLevel] = []
@export var asset_catalog: AssetCatalog

var _pending_level: MemoryBoardLevel
var _current_level: MemoryBoardLevel
var _logic: MemoryBoardLogic = MemoryBoardLogic.new()
var _cards: Array[MemoryCard] = []
var _title_label: LocalizedLabel
var _intro_label: LocalizedLabel
var _moves_label: LocalizedLabel
var _time_label: LocalizedLabel
var _hint_button: LocalizedButton
var _grid_holder: CenterContainer
var _grid: GridContainer
var _result_panel: MemoryResultPanel
var _pause_popup: PopupPanel
var _paused: bool = false
var _hint_revealing: bool = false
var _elapsed_seconds: float = 0.0
var _timer_started: bool = false
var _finished: bool = false
var _audio_player: AudioStreamPlayer


func _ready() -> void:
	if asset_catalog == null:
		asset_catalog = load("res://data/asset_catalog.tres") as AssetCatalog
	if sfx_flip == null and asset_catalog != null:
		sfx_flip = asset_catalog.sfx_ui_click
	_build_ui()
	EventBus.language_changed.connect(_on_language_changed)
	if _pending_level != null:
		var requested_level: MemoryBoardLevel = _pending_level
		_pending_level = null
		start_level(requested_level)


func _exit_tree() -> void:
	if EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.disconnect(_on_language_changed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_grid_holder):
		_fit_cards()


func start_level(level: MemoryBoardLevel) -> void:
	if level == null:
		push_error("MemoryBoard: start_level requires a valid level.")
		return
	if not is_inside_tree():
		_pending_level = level
		return
	_current_level = level
	var faction_bonus: FactionData = GameManager.get_faction_data()
	if not _logic.setup(level, -1, faction_bonus):
		return
	_elapsed_seconds = 0.0
	_timer_started = false
	_finished = false
	_paused = false
	_hint_revealing = false
	if is_instance_valid(_result_panel):
		_result_panel.visible = false
	for card: MemoryCard in _cards:
		card.queue_free()
	_cards.clear()
	_grid.columns = level.grid_columns
	for index: int in range(_logic.deck.size()):
		var card: MemoryCard = CARD_SCENE.instantiate() as MemoryCard
		if placeholder_card_back != null:
			card.placeholder_card_back = placeholder_card_back
		if placeholder_card_front != null:
			card.placeholder_card_front = placeholder_card_front
		if asset_catalog != null:
			if card.placeholder_card_back == null:
				card.placeholder_card_back = asset_catalog.panel_texture
			if card.placeholder_card_front == null:
				card.placeholder_card_front = asset_catalog.panel_texture
		card.custom_minimum_size = _card_size()
		card.configure(_logic.deck[index], index)
		card.pressed.connect(_on_card_pressed.bind(card))
		_grid.add_child(card)
		_cards.append(card)
	_refresh_header()
	_refresh_hint_button()
	call_deferred("_fit_cards")


func _process(delta: float) -> void:
	if _finished or _paused or not _timer_started:
		return
	_elapsed_seconds += delta
	_refresh_time_label()
	if _logic.effective_time_limit_seconds > 0.0 and _elapsed_seconds >= _logic.effective_time_limit_seconds:
		_finish_level(false)


func _build_ui() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.055, 0.065, 0.12)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margins: MarginContainer = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 22)
	margins.add_theme_constant_override("margin_right", 22)
	margins.add_theme_constant_override("margin_top", 30)
	margins.add_theme_constant_override("margin_bottom", 30)
	add_child(margins)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
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
	_intro_label.custom_minimum_size = Vector2(0.0, 44.0)
	layout.add_child(_intro_label)

	_grid_holder = CenterContainer.new()
	_grid_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_grid_holder)
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid_holder.add_child(_grid)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	layout.add_child(footer)
	_hint_button = LocalizedButton.new()
	_hint_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_button.custom_minimum_size = Vector2(0.0, 62.0)
	_hint_button.pressed.connect(_on_hint_pressed)
	footer.add_child(_hint_button)
	var pause_button: LocalizedButton = LocalizedButton.new()
	pause_button.translation_key = "ui.memory.pause_back"
	pause_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_button.custom_minimum_size = Vector2(0.0, 62.0)
	pause_button.pressed.connect(_open_pause_menu)
	footer.add_child(pause_button)
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = "SFX"
	add_child(_audio_player)
	_result_panel = RESULT_PANEL_SCENE.instantiate() as MemoryResultPanel
	_result_panel.retry_requested.connect(_on_retry_requested)
	_result_panel.next_requested.connect(_on_next_requested)
	_result_panel.back_to_map_requested.connect(_on_back_requested)
	add_child(_result_panel)
	_build_pause_menu()


func _build_pause_menu() -> void:
	_pause_popup = PopupPanel.new()
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360.0, 240.0)
	_pause_popup.add_child(panel)
	var controls: VBoxContainer = VBoxContainer.new()
	controls.add_theme_constant_override("separation", 14)
	panel.add_child(controls)
	var title: LocalizedLabel = LocalizedLabel.new()
	title.translation_key = "ui.memory.paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_child(title)
	var resume: LocalizedButton = LocalizedButton.new()
	resume.translation_key = "ui.memory.resume"
	resume.pressed.connect(func() -> void: _pause_popup.hide())
	controls.add_child(resume)
	var back: LocalizedButton = LocalizedButton.new()
	back.translation_key = "ui.memory.back_to_map"
	back.pressed.connect(_on_back_requested)
	controls.add_child(back)
	_pause_popup.popup_hide.connect(func() -> void: _paused = false)
	add_child(_pause_popup)


func _on_card_pressed(card: MemoryCard) -> void:
	if _finished or _paused or _hint_revealing:
		return
	if not _timer_started:
		_timer_started = true
	var outcome: FlipResult = _logic.flip(card.card_index)
	if not outcome.accepted:
		return
	card.set_face_up(true)
	_play_sfx(sfx_flip)
	_refresh_moves_label()
	if outcome.matched:
		_cards[outcome.pair_indices[0]].set_matched()
		_cards[outcome.pair_indices[1]].set_matched()
		_play_sfx(sfx_match)
		if outcome.failed:
			_finish_level(false)
		elif outcome.completed:
			_finish_level(true)
	elif outcome.mismatch:
		_cards[outcome.pair_indices[0]].shake_mismatch()
		_cards[outcome.pair_indices[1]].shake_mismatch()
		_play_sfx(sfx_mismatch)
		_resolve_mismatch_after_delay(outcome.pair_indices)
		if outcome.failed:
			_finish_level(false)
	elif outcome.failed:
		_finish_level(false)


func _resolve_mismatch_after_delay(indices: Array[int]) -> void:
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree() or _finished:
		return
	for index: int in indices:
		if index >= 0 and index < _cards.size():
			_cards[index].set_face_up(false)
	_logic.resolve_mismatch()


func _on_hint_pressed() -> void:
	if _finished or _paused or _hint_revealing or _logic.state == MemoryBoardLogic.BoardState.RESOLVING:
		return
	var indices: Array[int] = _logic.reveal_hint_pair()
	if indices.is_empty():
		return
	_hint_revealing = true
	_timer_started = true
	for index: int in indices:
		_cards[index].set_hint_revealed(true)
	_refresh_hint_button()
	await get_tree().create_timer(1.15).timeout
	if not is_inside_tree() or _finished:
		return
	for index: int in indices:
		_cards[index].set_hint_revealed(false)
	_hint_revealing = false


func _open_pause_menu() -> void:
	if _finished:
		return
	_paused = true
	_pause_popup.popup_centered(Vector2i(380, 250))


func _finish_level(completed: bool) -> void:
	if _finished:
		return
	_finished = true
	_paused = false
	var result: PuzzleResult = PuzzleResult.new()
	result.puzzle_id = _current_level.id
	result.completed = completed
	result.moves = _logic.moves
	result.time_seconds = _elapsed_seconds
	result.hints_used = _logic.hints_used
	result.stars = _logic.calculate_stars() if completed else 0
	if completed:
		_play_sfx(sfx_win)
	_result_panel.show_result(result, _next_level() != null)
	level_finished.emit(result)


func _next_level() -> MemoryBoardLevel:
	var current_index: int = -1
	for index: int in range(level_sequence.size()):
		if level_sequence[index].id == _current_level.id:
			current_index = index
			break
	if current_index >= 0 and current_index + 1 < level_sequence.size():
		return level_sequence[current_index + 1]
	return null


func _on_retry_requested() -> void:
	start_level(_current_level)


func _on_next_requested() -> void:
	var next: MemoryBoardLevel = _next_level()
	if next != null:
		start_level(next)


func _on_back_requested() -> void:
	if is_instance_valid(_pause_popup):
		_pause_popup.hide()
	exit_requested.emit()


func _on_language_changed(_locale: String) -> void:
	_refresh_header()
	_refresh_hint_button()


func _refresh_header() -> void:
	if _current_level == null or not is_instance_valid(_title_label):
		return
	_title_label.set_localized(_current_level.title_key)
	_intro_label.set_localized(_current_level.intro_key)
	_refresh_moves_label()
	_refresh_time_label()


func _refresh_moves_label() -> void:
	if _current_level == null or not is_instance_valid(_moves_label):
		return
	var limit: int = _logic.effective_max_moves
	var display_limit: String = str(limit) if limit > 0 else Localization.translate("ui.memory.unlimited")
	_moves_label.set_localized("ui.memory.moves", {
		"moves": _logic.moves,
		"limit": display_limit,
	})


func _refresh_time_label() -> void:
	if not is_instance_valid(_time_label):
		return
	var display_time: String = _format_time(_elapsed_seconds)
	if _logic.effective_time_limit_seconds > 0.0:
		display_time += " / " + _format_time(_logic.effective_time_limit_seconds)
	_time_label.set_localized("ui.memory.time", {"time": display_time})


func _refresh_hint_button() -> void:
	if not is_instance_valid(_hint_button):
		return
	_hint_button.set_localized("ui.memory.hint", {
		"count": maxi(0, _logic.hint_allowance - _logic.hints_used),
	})
	_hint_button.disabled = _logic.hints_used >= _logic.hint_allowance or _finished


func _fit_cards() -> void:
	if _current_level == null or _cards.is_empty() or _grid_holder.size.x <= 0.0 or _grid_holder.size.y <= 0.0:
		return
	var minimum_size: Vector2 = _card_size()
	for card: MemoryCard in _cards:
		card.custom_minimum_size = minimum_size


func _card_size() -> Vector2:
	if _current_level == null:
		return Vector2(140.0, 160.0)
	var available_width: float = maxf(88.0, (_grid_holder.size.x - 10.0 * float(_current_level.grid_columns - 1)) / float(_current_level.grid_columns))
	var available_height: float = maxf(88.0, (_grid_holder.size.y - 10.0 * float(_current_level.grid_rows - 1)) / float(_current_level.grid_rows))
	return Vector2(minf(170.0, available_width), minf(190.0, available_height))


func _format_time(seconds: float) -> String:
	var whole_seconds: int = floori(seconds)
	return "%02d:%02d" % [floori(float(whole_seconds) / 60.0), whole_seconds % 60]


func _play_sfx(stream: AudioStream) -> void:
	if stream == null or not is_instance_valid(_audio_player):
		return
	_audio_player.stream = stream
	_audio_player.play()
