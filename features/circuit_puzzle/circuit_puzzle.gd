## CircuitPuzzle — Main UI and controller for the Circuit Puzzle feature.
## Connects CircuitLogic to the UI grid, handles input, sound, animations,
## responsive re-layout, hint requests, modal popups, and level completion.
class_name CircuitPuzzle
extends Control


## Emitted when the level is completed with a PuzzleResult.
signal level_finished(result: PuzzleResult)

## Emitted when the player requests to exit to menu/map.
signal exit_requested()


# ── Asset Placeholder Exports ────────────────────────────────────────────────
@export var placeholder_tile_texture: Texture2D
@export var placeholder_source_texture: Texture2D
@export var placeholder_target_texture: Texture2D
@export var placeholder_blocker_texture: Texture2D

@export var sfx_rotate: AudioStream
@export var sfx_powered: AudioStream
@export var sfx_solved: AudioStream


# ── Preloaded Tile Scene ─────────────────────────────────────────────────────
const TILE_SCENE: PackedScene = preload("res://features/circuit_puzzle/circuit_tile.tscn")

# ── References ───────────────────────────────────────────────────────────────
var _logic: CircuitLogic = CircuitLogic.new()
var _current_level: CircuitLevel
var _tile_views: Dictionary = {} # Vector2i -> CircuitTile
var _is_animating_flow: bool = false
var _elapsed_time: float = 0.0
var _timer_active: bool = false

# Nodes created in tree or via scene
var _audio_sfx: AudioStreamPlayer
var _grid_container: Control
var _title_label: Label
var _moves_label: Label
var _par_label: Label
var _time_label: Label
var _hint_button: Button
var _restart_button: Button
var _back_button: Button

# Popups
var _concept_modal: PanelContainer
var _concept_title: Label
var _concept_desc: Label
var _concept_hint: Label
var _concept_close_btn: Button

# Win panel
var _win_panel: PanelContainer
var _win_title: Label
var _win_stars_label: Label
var _win_moves_label: Label
var _win_next_btn: Button
var _win_retry_btn: Button
var _win_back_btn: Button


func _ready() -> void:
	EventBus.language_changed.connect(_on_language_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_build_ui()


func _exit_tree() -> void:
	if EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.disconnect(_on_language_changed)


func _process(delta: float) -> void:
	if _timer_active:
		_elapsed_time += delta
		_update_time_display()


# ── Public API ───────────────────────────────────────────────────────────────

## Starts a new puzzle with the specified CircuitLevel resource.
func start_level(level: CircuitLevel) -> void:
	assert(level != null, "CircuitPuzzle: level cannot be null.")
	_current_level = level
	_elapsed_time = 0.0
	_timer_active = true
	_is_animating_flow = false

	# Hide win panel and concept modal
	if _win_panel:
		_win_panel.visible = false
	if _concept_modal:
		_concept_modal.visible = false

	# Initialize logic
	_logic.load_level(_current_level)

	# Build and layout grid tiles
	_build_grid()
	_update_hud()
	_update_powered_tiles(false)


# ── Internal Grid Building & Layout ──────────────────────────────────────────

func _build_grid() -> void:
	# Clear existing tiles
	for cell: Variant in _tile_views.keys():
		var tile_ctrl: CircuitTile = _tile_views[cell] as CircuitTile
		if is_instance_valid(tile_ctrl):
			tile_ctrl.queue_free()
	_tile_views.clear()

	if _current_level == null or _grid_container == null:
		return

	for y: int in range(_logic.rows):
		for x: int in range(_logic.columns):
			var cell: Vector2i = Vector2i(x, y)
			var tile_view: CircuitTile = TILE_SCENE.instantiate() as CircuitTile
			tile_view.placeholder_tile_texture = placeholder_tile_texture
			tile_view.placeholder_source_texture = placeholder_source_texture
			tile_view.placeholder_target_texture = placeholder_target_texture
			tile_view.placeholder_blocker_texture = placeholder_blocker_texture

			var type: CircuitTileDef.CircuitTileType = _logic.get_tile_type(cell)
			var rot: int = _logic.get_tile_rotation(cell)
			var locked: bool = _logic.is_tile_locked(cell)
			var lbl: String = _logic.get_tile_label_key(cell)

			tile_view.setup(cell, type, rot, locked, lbl, false)
			tile_view.tile_tapped.connect(_on_tile_tapped)
			tile_view.tile_long_pressed.connect(_on_tile_long_pressed)

			_grid_container.add_child(tile_view)
			_tile_views[cell] = tile_view

	_layout_grid()


func _layout_grid() -> void:
	if _current_level == null or _grid_container == null:
		return

	var area_size: Vector2 = _grid_container.size
	if area_size.x <= 0 or area_size.y <= 0:
		return

	var cols: int = _logic.columns
	var rws: int = _logic.rows
	var padding: float = 8.0

	var avail_w: float = area_size.x - padding * float(cols + 1)
	var avail_h: float = area_size.y - padding * float(rws + 1)

	var tile_size_val: float = minf(avail_w / float(cols), avail_h / float(rws))
	# Minimum 88px constraint as required by mobile touch target guidelines
	tile_size_val = maxf(88.0, tile_size_val)

	var grid_w: float = float(cols) * tile_size_val + float(cols - 1) * padding
	var grid_h: float = float(rws) * tile_size_val + float(rws - 1) * padding

	var start_x: float = maxf(0.0, (area_size.x - grid_w) / 2.0)
	var start_y: float = maxf(0.0, (area_size.y - grid_h) / 2.0)

	for y: int in range(rws):
		for x: int in range(cols):
			var cell: Vector2i = Vector2i(x, y)
			if _tile_views.has(cell):
				var tile: CircuitTile = _tile_views[cell] as CircuitTile
				var pos: Vector2 = Vector2(
					start_x + float(x) * (tile_size_val + padding),
					start_y + float(y) * (tile_size_val + padding)
				)
				tile.position = pos
				tile.size = Vector2(tile_size_val, tile_size_val)


func _on_viewport_resized() -> void:
	call_deferred(&"_layout_grid")


# ── Gameplay Interactions ────────────────────────────────────────────────────

func _on_tile_tapped(cell: Vector2i) -> void:
	if not _timer_active:
		return

	var rotated: bool = _logic.rotate_tile(cell)
	if not rotated:
		return

	_play_sfx(sfx_rotate)

	# Visual update happens immediately
	if _tile_views.has(cell):
		var tile: CircuitTile = _tile_views[cell] as CircuitTile
		tile.animate_rotation(_logic.get_tile_rotation(cell))

	_update_hud()
	_update_powered_tiles(true)

	if _logic.is_solved():
		_handle_puzzle_won()


func _update_powered_tiles(animated: bool) -> void:
	var powered_map: Dictionary = _logic.compute_powered()
	var any_target_powered: bool = false

	for cell_var: Variant in powered_map.keys():
		var cell: Vector2i = cell_var as Vector2i
		var is_pw: bool = powered_map[cell] as bool
		if _tile_views.has(cell):
			var tile: CircuitTile = _tile_views[cell] as CircuitTile
			tile.set_powered(is_pw, animated)
			if is_pw and tile.tile_type == CircuitTileDef.CircuitTileType.TARGET:
				any_target_powered = true

	if any_target_powered and animated:
		_play_sfx(sfx_powered)


func _handle_puzzle_won() -> void:
	_timer_active = false
	_play_sfx(sfx_solved)

	# Staggered energy propagation animation along BFS order
	var bfs_order: Array[Vector2i] = _logic.last_bfs_order.duplicate()
	var flow_tween: Tween = create_tween()
	var step_delay: float = 0.05
	for i: int in range(bfs_order.size()):
		var cell: Vector2i = bfs_order[i]
		if _tile_views.has(cell):
			var tile: CircuitTile = _tile_views[cell] as CircuitTile
			flow_tween.parallel().tween_callback(func() -> void:
				tile.scale = Vector2(1.15, 1.15)
				var pop_tw: Tween = create_tween()
				pop_tw.tween_property(tile, "scale", Vector2.ONE, 0.2)
			).set_delay(float(i) * step_delay)

	# Show win panel after flow completes
	flow_tween.tween_callback(_show_win_panel).set_delay(0.3)


func _show_win_panel() -> void:
	var stars: int = _logic.calculate_stars()
	var result: PuzzleResult = PuzzleResult.new()
	result.puzzle_id = _current_level.id
	result.completed = true
	result.stars = stars
	result.moves = _logic.moves
	result.time_seconds = _elapsed_time
	result.hints_used = _logic.hints_used

	GameManager.register_puzzle_result(result)
	level_finished.emit(result)

	if _win_panel:
		_win_panel.visible = true
		var star_str: String = ""
		for s: int in range(3):
			star_str += "★ " if s < stars else "☆ "
		_win_stars_label.text = star_str.strip_edges()

		var par: int = _current_level.par_moves
		_win_moves_label.text = Localization.translate("ui.circuit.moves_result", {
			"moves": _logic.moves,
			"par": par
		})


func _on_hint_pressed() -> void:
	if not _timer_active:
		return

	var hint_cell: Vector2i = _logic.get_hint()
	if hint_cell == Vector2i(-1, -1):
		return

	_logic.hints_used += 1

	# Highlight hint tile visually
	if _tile_views.has(hint_cell):
		var tile: CircuitTile = _tile_views[hint_cell] as CircuitTile
		var tw: Tween = create_tween().set_loops(3)
		tw.tween_property(tile, "modulate", Color(2.0, 2.0, 1.0, 1.0), 0.15)
		tw.tween_property(tile, "modulate", Color.WHITE, 0.15)
		Haptics.vibrate(50)


func _on_restart_pressed() -> void:
	if _current_level != null:
		start_level(_current_level)


func _on_back_pressed() -> void:
	exit_requested.emit()


func _on_tile_long_pressed(_cell: Vector2i, p_label_key: String) -> void:
	_show_concept_popup(p_label_key)


func _show_concept_popup(p_label_key: String) -> void:
	if _concept_modal == null:
		return

	var title_text: String = Localization.translate(p_label_key + ".name")
	var desc_text: String = Localization.translate(p_label_key + ".definition")
	var hint_text: String = Localization.translate(p_label_key + ".hint")

	_concept_title.text = title_text
	_concept_desc.text = desc_text
	_concept_hint.text = hint_text
	_concept_modal.visible = true


func _on_language_changed(_locale: String) -> void:
	_update_hud()


# ── HUD Display ──────────────────────────────────────────────────────────────

func _update_hud() -> void:
	if _current_level == null:
		return

	if _title_label:
		_title_label.text = Localization.translate(_current_level.title_key)
	if _moves_label:
		_moves_label.text = Localization.translate("ui.circuit.moves", {"moves": _logic.moves})
	if _par_label:
		_par_label.text = Localization.translate("ui.circuit.par", {"par": _current_level.par_moves})


func _update_time_display() -> void:
	if _time_label == null:
		return
	var time_val: float = _elapsed_time
	if _current_level != null and _current_level.time_limit_seconds > 0.0:
		var bonus: float = 0.0
		var faction_data: FactionData = GameManager.get_faction_data()
		if faction_data != null:
			bonus = faction_data.time_bonus_seconds
		var total_limit: float = _current_level.time_limit_seconds + bonus
		var remaining: float = maxf(0.0, total_limit - _elapsed_time)
		_time_label.text = "%02d:%02d" % [int(remaining) / 60, int(remaining) % 60]
		if remaining <= 0.0 and _timer_active:
			_timer_active = false
			# Time ran out
	else:
		_time_label.text = "%02d:%02d" % [int(time_val) / 60, int(time_val) % 60]


func _play_sfx(stream: AudioStream) -> void:
	if stream == null or _audio_sfx == null:
		return
	_audio_sfx.stream = stream
	_audio_sfx.play()


# ── UI Construction ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	# Audio player
	_audio_sfx = AudioStreamPlayer.new()
	_audio_sfx.bus = &"SFX"
	add_child(_audio_sfx)

	# Root Safe Area Container
	var safe_area: SafeAreaContainer = SafeAreaContainer.new()
	safe_area.set_anchors_preset(PRESET_FULL_RECT)
	add_child(safe_area)

	# Main Vertical Layout
	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 12)
	safe_area.add_child(main_vbox)

	# Top Bar (Title, HUD info, Back)
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 64)
	main_vbox.add_child(top_bar)

	_back_button = Button.new()
	_back_button.custom_minimum_size = Vector2(88, 56)
	_back_button.text = "<"
	_back_button.pressed.connect(_on_back_pressed)
	top_bar.add_child(_back_button)

	_title_label = Label.new()
	_title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(_title_label)

	_restart_button = Button.new()
	_restart_button.custom_minimum_size = Vector2(88, 56)
	_restart_button.text = "⟳"
	_restart_button.pressed.connect(_on_restart_pressed)
	top_bar.add_child(_restart_button)

	# HUD Stats row
	var stats_hbox: HBoxContainer = HBoxContainer.new()
	stats_hbox.custom_minimum_size = Vector2(0, 40)
	main_vbox.add_child(stats_hbox)

	_moves_label = Label.new()
	_moves_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_hbox.add_child(_moves_label)

	_par_label = Label.new()
	_par_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_par_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_hbox.add_child(_par_label)

	_time_label = Label.new()
	_time_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_hbox.add_child(_time_label)

	# Central Grid Container area
	_grid_container = Control.new()
	_grid_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_grid_container.size_flags_vertical = SIZE_EXPAND_FILL
	_grid_container.resized.connect(_on_viewport_resized)
	main_vbox.add_child(_grid_container)

	# Bottom Bar (Hint button)
	var bottom_bar: HBoxContainer = HBoxContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 88)
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(bottom_bar)

	_hint_button = Button.new()
	_hint_button.custom_minimum_size = Vector2(240, 72)
	_hint_button.text = "Hint"
	_hint_button.pressed.connect(_on_hint_pressed)
	bottom_bar.add_child(_hint_button)

	# Build Concept Modal & Win Panel overlays
	_build_concept_modal()
	_build_win_panel()


func _build_concept_modal() -> void:
	_concept_modal = PanelContainer.new()
	_concept_modal.visible = false
	_concept_modal.set_anchors_preset(PRESET_CENTER)
	_concept_modal.custom_minimum_size = Vector2(500, 320)
	add_child(_concept_modal)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_concept_modal.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	_concept_title = Label.new()
	_concept_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_concept_title)

	_concept_desc = Label.new()
	_concept_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_concept_desc)

	_concept_hint = Label.new()
	_concept_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_concept_hint)

	_concept_close_btn = Button.new()
	_concept_close_btn.custom_minimum_size = Vector2(160, 56)
	_concept_close_btn.size_flags_horizontal = SIZE_SHRINK_CENTER
	_concept_close_btn.text = "OK"
	_concept_close_btn.pressed.connect(func() -> void: _concept_modal.visible = false)
	vbox.add_child(_concept_close_btn)


func _build_win_panel() -> void:
	_win_panel = PanelContainer.new()
	_win_panel.visible = false
	_win_panel.set_anchors_preset(PRESET_CENTER)
	_win_panel.custom_minimum_size = Vector2(520, 360)
	add_child(_win_panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_win_panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	_win_title = Label.new()
	_win_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_title.text = "Circuit Restored!"
	vbox.add_child(_win_title)

	_win_stars_label = Label.new()
	_win_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_win_stars_label)

	_win_moves_label = Label.new()
	_win_moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_win_moves_label)

	var btns_hbox: HBoxContainer = HBoxContainer.new()
	btns_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btns_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(btns_hbox)

	_win_retry_btn = Button.new()
	_win_retry_btn.custom_minimum_size = Vector2(130, 60)
	_win_retry_btn.text = "Retry"
	_win_retry_btn.pressed.connect(_on_restart_pressed)
	btns_hbox.add_child(_win_retry_btn)

	_win_back_btn = Button.new()
	_win_back_btn.custom_minimum_size = Vector2(130, 60)
	_win_back_btn.text = "Menu"
	_win_back_btn.pressed.connect(_on_back_pressed)
	btns_hbox.add_child(_win_back_btn)
