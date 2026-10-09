## World map — pannable overview of all territories with unlock/complete state.
class_name WorldMap
extends Control

const TERRITORY_PATHS: Array[String] = [
	"res://data/territories/territory_01.tres",
	"res://data/territories/territory_02.tres",
	"res://data/territories/territory_03.tres",
	"res://data/territories/territory_04.tres",
	"res://data/territories/territory_05.tres",
	"res://data/territories/territory_06.tres",
]

const _DRAG_DAMPING: float = 0.88
const _MARKER_SIZE: Vector2 = Vector2(96.0, 96.0)

@export var placeholder_map_background: Texture2D = null
@export var asset_catalog: AssetCatalog = preload("res://data/asset_catalog.tres")

var _territories: Array[TerritoryData] = []
var _markers: Dictionary = {} # StringName -> Button
var _map_layer: Control
var _drag_start: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _velocity: Vector2 = Vector2.ZERO

# Detail panel
var _detail_panel: PanelContainer
var _detail_title: Label
var _detail_desc: Label
var _detail_stars: Label
var _detail_status: Label
var _detail_puzzle_list: VBoxContainer
var _detail_close: Button
var _selected_territory: TerritoryData = null

# Celebration toast
var _toast: ToastNotification


func _ready() -> void:
	_load_territories()
	_build_ui()
	_populate_markers()
	EventBus.territory_unlocked.connect(_on_territory_unlocked)
	EventBus.language_changed.connect(_on_language_changed)

	var current_faction: FactionData = GameManager.get_faction_data()
	if current_faction != null and current_faction.placeholder_music != null:
		AudioManager.play_music(current_faction.placeholder_music)
	elif asset_catalog != null and asset_catalog.music_world_map != null:
		AudioManager.play_music(asset_catalog.music_world_map)


func _exit_tree() -> void:
	if EventBus.territory_unlocked.is_connected(_on_territory_unlocked):
		EventBus.territory_unlocked.disconnect(_on_territory_unlocked)
	if EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.disconnect(_on_language_changed)


func _load_territories() -> void:
	for path: String in TERRITORY_PATHS:
		if ResourceLoader.exists(path):
			var t: Resource = ResourceLoader.load(path)
			if t is TerritoryData:
				_territories.append(t as TerritoryData)
			else:
				push_error("WorldMap: Resource is not TerritoryData: " + path)
		else:
			push_error("WorldMap: Territory resource not found: " + path)


func _build_ui() -> void:
	# Background
	if placeholder_map_background != null:
		var bg_tex: TextureRect = TextureRect.new()
		bg_tex.texture = placeholder_map_background
		bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_tex.set_anchors_preset(PRESET_FULL_RECT)
		add_child(bg_tex)
	else:
		var bg: ColorRect = ColorRect.new()
		bg.color = Color(0.08, 0.07, 0.13, 1.0)
		bg.set_anchors_preset(PRESET_FULL_RECT)
		add_child(bg)

	# Scrollable map layer
	_map_layer = Control.new()
	_map_layer.set_anchors_preset(PRESET_FULL_RECT)
	_map_layer.mouse_filter = MOUSE_FILTER_PASS
	add_child(_map_layer)

	# Header bar
	var header: HBoxContainer = HBoxContainer.new()
	header.set_anchors_preset(PRESET_TOP_WIDE)
	header.custom_minimum_size = Vector2(0, 80)
	header.mouse_filter = MOUSE_FILTER_PASS
	add_child(header)

	var back_btn: Button = Button.new()
	back_btn.text = Localization.translate("ui.world_map.back")
	back_btn.custom_minimum_size = Vector2(88, 72)
	back_btn.pressed.connect(func() -> void: SceneManager.change_scene("res://ui/main_menu/main_menu.tscn"))
	header.add_child(back_btn)

	var title_lbl: Label = Label.new()
	title_lbl.text = Localization.translate("ui.world_map.title")
	title_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	header.add_child(title_lbl)

	var stars_lbl: Label = Label.new()
	stars_lbl.text = Localization.translate("ui.stars_count", {"stars": GameManager.get_total_stars()})
	stars_lbl.custom_minimum_size = Vector2(100, 0)
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	header.add_child(stars_lbl)

	# Detail panel (hidden by default)
	_detail_panel = PanelContainer.new()
	_detail_panel.custom_minimum_size = Vector2(360, 0)
	_detail_panel.visible = false
	_detail_panel.set_anchors_preset(PRESET_CENTER_RIGHT)
	_detail_panel.anchor_left = 0.5
	_detail_panel.anchor_right = 1.0
	_detail_panel.anchor_top = 0.1
	_detail_panel.anchor_bottom = 0.9
	add_child(_detail_panel)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_detail_panel.add_child(vb)

	_detail_close = Button.new()
	_detail_close.text = Localization.translate("ui.world_map.close")
	_detail_close.custom_minimum_size = Vector2(88, 48)
	_detail_close.pressed.connect(func() -> void: _detail_panel.visible = false)
	vb.add_child(_detail_close)

	_detail_title = Label.new()
	_detail_title.add_theme_font_size_override("font_size", 22)
	_detail_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	vb.add_child(_detail_title)

	_detail_desc = Label.new()
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_detail_desc)

	_detail_stars = Label.new()
	_detail_stars.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vb.add_child(_detail_stars)

	_detail_status = Label.new()
	_detail_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	vb.add_child(_detail_status)

	var sep: HSeparator = HSeparator.new()
	vb.add_child(sep)

	_detail_puzzle_list = VBoxContainer.new()
	_detail_puzzle_list.add_theme_constant_override("separation", 8)
	vb.add_child(_detail_puzzle_list)

	# Toast notification for unlock celebrations
	_toast = ToastNotification.new()
	add_child(_toast)


func _populate_markers() -> void:
	var map_size: Vector2 = get_viewport_rect().size
	for t: TerritoryData in _territories:
		var marker: Button = Button.new()
		var unlocked: bool = GameManager.is_territory_unlocked(t.id)
		marker.text = "◉" if unlocked else "🔒"
		marker.custom_minimum_size = _MARKER_SIZE
		marker.set_anchors_preset(PRESET_TOP_LEFT)
		marker.position = Vector2(
			t.map_position.x * map_size.x - (_MARKER_SIZE.x * 0.5),
			t.map_position.y * map_size.y - (_MARKER_SIZE.y * 0.5)
		)

		if unlocked:
			marker.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
		else:
			marker.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))

		marker.pressed.connect(func() -> void: _show_territory(t))
		_map_layer.add_child(marker)
		_markers[t.id] = marker


func _show_territory(t: TerritoryData) -> void:
	_selected_territory = t
	_detail_title.text = Localization.translate(t.name_key)
	_detail_desc.text = Localization.translate(t.description_key)

	var is_unlocked: bool = GameManager.is_territory_unlocked(t.id)

	# Clear previous puzzle rows
	for child: Node in _detail_puzzle_list.get_children():
		child.queue_free()

	if is_unlocked:
		var total_stars: int = 0
		for pid: String in t.puzzle_ids:
			total_stars += GameManager.get_best_stars(pid)
		_detail_stars.text = Localization.translate("ui.world_map.stars_progress", {
			"current": total_stars,
			"total": t.puzzle_ids.size() * 3
		})
		_detail_status.text = ""

		for pid: String in t.puzzle_ids:
			var row: HBoxContainer = HBoxContainer.new()
			var p_title_key: String = "puzzle." + pid + ".title"
			var display_name: String = Localization.translate(p_title_key) if Localization.has_key(p_title_key) else pid

			var lbl: Label = Label.new()
			lbl.text = display_name
			lbl.size_flags_horizontal = SIZE_EXPAND_FILL
			row.add_child(lbl)

			var stars_lbl: Label = Label.new()
			var best: int = GameManager.get_best_stars(pid)
			stars_lbl.text = "★".repeat(best) + "☆".repeat(3 - best)
			stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			row.add_child(stars_lbl)

			var play_btn: Button = Button.new()
			play_btn.text = Localization.translate("ui.world_map.play")
			play_btn.custom_minimum_size = Vector2(88, 44)
			var target_id: String = pid
			play_btn.pressed.connect(func() -> void: PuzzleLauncher.launch_puzzle(target_id))
			row.add_child(play_btn)

			_detail_puzzle_list.add_child(row)
	else:
		_detail_stars.text = ""
		# Format unlock requirement
		var req_reasons: Array[String] = []
		if t.required_territory_id != &"":
			var req_name_key: String = "territory." + str(t.required_territory_id).replace("territory_", "") + ".name"
			var terr_name: String = Localization.translate(req_name_key) if Localization.has_key(req_name_key) else str(t.required_territory_id)
			req_reasons.append(Localization.translate("ui.world_map.req_territory", {"territory": terr_name}))
		if t.required_stars > GameManager.get_total_stars():
			req_reasons.append(Localization.translate("ui.world_map.req_stars", {"stars": t.required_stars}))

		var reason_text: String = " • ".join(req_reasons)
		_detail_status.text = Localization.translate("ui.world_map.territory_locked", {"reason": reason_text})

	_detail_panel.visible = true


# ── Drag / inertia ────────────────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			_drag_start = touch.position
			_is_dragging = true
			_velocity = Vector2.ZERO
		else:
			_is_dragging = false
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if _is_dragging:
			_map_layer.position += drag.relative
			_clamp_map_position()
			_velocity = drag.relative


func _process(_delta: float) -> void:
	if not _is_dragging and _velocity.length() > 1.0:
		_map_layer.position += _velocity
		_clamp_map_position()
		_velocity *= _DRAG_DAMPING


func _clamp_map_position() -> void:
	var view_size: Vector2 = get_viewport_rect().size
	_map_layer.position.x = clampf(_map_layer.position.x, -view_size.x * 0.4, view_size.x * 0.4)
	_map_layer.position.y = clampf(_map_layer.position.y, -view_size.y * 0.4, view_size.y * 0.4)


func _on_territory_unlocked(id: StringName) -> void:
	if _markers.has(id):
		var marker: Button = _markers[id] as Button
		marker.text = "◉"
		marker.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))

	for t: TerritoryData in _territories:
		if t.id == id:
			var terr_name: String = Localization.translate(t.name_key)
			var msg: String = Localization.translate("unlock.territory", {"name": terr_name})
			_toast.show_message(msg, 3.0)
			if asset_catalog != null and asset_catalog.sfx_territory_unlocked != null:
				AudioManager.play_sfx(asset_catalog.sfx_territory_unlocked)
			break


func _on_language_changed(_locale: String) -> void:
	if _selected_territory != null and _detail_panel.visible:
		_show_territory(_selected_territory)
