## Scrollable Eldoria map with progress-aware territory markers.
extends Control

const SETTINGS_SCENE: PackedScene = preload("res://ui/settings/settings_menu.tscn")
const PANEL_SCRIPT: Script = preload("res://ui/world_map/territory_panel.gd")
const LAUNCHER_SCENE: PackedScene = preload("res://ui/world_map/puzzle_launcher.tscn")
const BOARD_SIZE: Vector2 = Vector2(900.0, 1600.0)

var _scroll: ScrollContainer
var _board: Control
var _markers: Dictionary[StringName, GameButton] = {}
var _panel: TerritoryPanel
var _toast: Toast
var _launcher: PuzzleLauncher
var _background_texture: Texture2D
var _stars_label: LocalizedLabel


func _ready() -> void:
	_build_map()
	EventBus.progress_changed.connect(_refresh_markers)
	EventBus.territory_unlocked.connect(_on_territory_unlocked)
	EventBus.language_changed.connect(_on_language_changed)
	_refresh_markers()
	AudioManager.play_map_ambience()
	var focus_id: StringName = StringName(str(SceneManager.current_params.get("focus_territory", "")))
	if focus_id != &"":
		call_deferred("_focus_territory", focus_id)
	else:
		call_deferred("_scroll_to_territory", &"territory_01", false)


func _exit_tree() -> void:
	if EventBus.progress_changed.is_connected(_refresh_markers):
		EventBus.progress_changed.disconnect(_refresh_markers)
	if EventBus.territory_unlocked.is_connected(_on_territory_unlocked):
		EventBus.territory_unlocked.disconnect(_on_territory_unlocked)
	if EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.disconnect(_on_language_changed)


func _build_map() -> void:
	var safe: SafeAreaContainer = SafeAreaContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_child(layout)
	var header: HBoxContainer = HBoxContainer.new()
	layout.add_child(header)
	var title: LocalizedLabel = LocalizedLabel.new()
	title.translation_key = "ui.map.title"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 26)
	header.add_child(title)
	_stars_label = LocalizedLabel.new()
	header.add_child(_stars_label)
	var back: GameButton = GameButton.new()
	back.set_localized("ui.common.back")
	back.pressed.connect(SceneManager.go_back)
	header.add_child(back)
	var settings: GameButton = GameButton.new()
	settings.set_localized("ui.menu.settings")
	settings.pressed.connect(_open_settings)
	header.add_child(settings)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.scroll_deadzone = 12
	layout.add_child(_scroll)
	_board = Control.new()
	_board.custom_minimum_size = BOARD_SIZE
	_board.size = BOARD_SIZE
	_scroll.add_child(_board)
	var catalog: AssetCatalog = load("res://data/asset_catalog.tres") as AssetCatalog
	if catalog != null:
		_background_texture = catalog.placeholder_map_background
	if _background_texture != null:
		var background: TextureRect = TextureRect.new()
		background.texture = _background_texture
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_board.add_child(background)
	else:
		_add_procedural_backdrop()
	var markers_layer: Control = Control.new()
	markers_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	markers_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(markers_layer)
	for territory: TerritoryData in GameManager.get_territories():
		var marker: GameButton = GameButton.new()
		marker.custom_minimum_size = Vector2(210.0, 88.0)
		marker.size = marker.custom_minimum_size
		marker.pressed.connect(_open_territory.bind(territory))
		marker.position = Vector2(
			territory.map_position.x * (BOARD_SIZE.x - marker.size.x),
			territory.map_position.y * (BOARD_SIZE.y - marker.size.y)
		)
		markers_layer.add_child(marker)
		_markers[territory.id] = marker
	_panel = PANEL_SCRIPT.new() as TerritoryPanel
	_panel.play_requested.connect(_launch_puzzle)
	add_child(_panel)
	_panel.visible = false
	_toast = Toast.new()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.position.y = 24.0
	_toast.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if catalog != null:
		_toast.placeholder_vfx = catalog.placeholder_unlock_vfx
	add_child(_toast)


func _add_procedural_backdrop() -> void:
	var texture: GradientTexture2D = GradientTexture2D.new()
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0.07, 0.13, 0.21))
	gradient.set_color(1, Color(0.20, 0.28, 0.27))
	texture.gradient = gradient
	texture.width = 1
	texture.height = 2
	var background: TextureRect = TextureRect.new()
	background.texture = texture
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_child(background)


func _refresh_markers() -> void:
	if is_instance_valid(_stars_label):
		_stars_label.set_localized("ui.map.total_stars", {"stars": GameManager.get_total_stars()})
	for territory: TerritoryData in GameManager.get_territories():
		if not _markers.has(territory.id):
			continue
		var completed: int = GameManager.get_territory_completed_puzzle_count(territory)
		var stars: int = 0
		for entry: TerritoryPuzzleEntry in territory.puzzle_ids:
			if entry != null:
				stars += GameManager.get_best_stars(entry.puzzle_id)
		var status: String = Localization.translate(
			"ui.map.completed" if completed == territory.puzzle_ids.size() else (
				"ui.map.unlocked" if GameManager.is_territory_unlocked(territory.id) else "ui.map.locked"
			)
		)
		var button: GameButton = _markers[territory.id]
		button.set_localized("ui.map.marker", {
			"name": Localization.translate(territory.name_key),
			"status": status,
			"stars": stars,
			"max_stars": territory.puzzle_ids.size() * 3,
		})
		var catalog: AssetCatalog = load("res://data/asset_catalog.tres") as AssetCatalog
		var marker_texture: Texture2D = territory.placeholder_icon
		if not GameManager.is_territory_unlocked(territory.id):
			marker_texture = territory.placeholder_locked_icon
			if marker_texture == null and catalog != null:
				marker_texture = catalog.placeholder_territory_locked_icon
		elif marker_texture == null and catalog != null:
			marker_texture = catalog.placeholder_territory_icon
		button.icon = marker_texture
		button.modulate = Color.WHITE if GameManager.is_territory_unlocked(territory.id) else Color(0.66, 0.68, 0.76)


func _open_territory(territory: TerritoryData) -> void:
	_panel.open(territory)


func _launch_puzzle(entry: TerritoryPuzzleEntry) -> void:
	if _panel != null:
		_panel.close_panel()
	_launcher = LAUNCHER_SCENE.instantiate() as PuzzleLauncher
	_launcher.launch(entry, _panel.get_puzzle_entries())
	_launcher.closed.connect(_on_launcher_closed)
	add_child(_launcher)


func _on_launcher_closed() -> void:
	var territory: TerritoryData = _panel.get_territory()
	_panel.open(GameManager.get_territory(territory.id) if territory != null else null)
	_refresh_markers()


func _open_settings() -> void:
	add_child(SETTINGS_SCENE.instantiate())


func _on_language_changed(_locale: String) -> void:
	_refresh_markers()


func _on_territory_unlocked(territory_id: StringName) -> void:
	var territory: TerritoryData = GameManager.get_territory(territory_id)
	if territory != null:
		_toast.show_key("ui.map.territory_unlocked", {
			"territory": Localization.translate(territory.name_key),
		})
	_refresh_markers()


func _focus_territory(territory_id: StringName) -> void:
	_scroll_to_territory(territory_id, true)


func _scroll_to_territory(territory_id: StringName, open_panel: bool) -> void:
	if not _markers.has(territory_id):
		return
	await get_tree().process_frame
	var marker: Control = _markers[territory_id]
	_scroll.scroll_horizontal = clampi(roundi(marker.position.x - _scroll.size.x * 0.5), 0, roundi(_scroll.get_h_scroll_bar().max_value))
	_scroll.scroll_vertical = clampi(roundi(marker.position.y - _scroll.size.y * 0.5), 0, roundi(_scroll.get_v_scroll_bar().max_value))
	var territory: TerritoryData = GameManager.get_territory(territory_id)
	if open_panel and territory != null:
		_open_territory(territory)
