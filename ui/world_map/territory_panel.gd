## Localized territory details and puzzle list overlay.
class_name TerritoryPanel
extends Control

signal play_requested(entry: TerritoryPuzzleEntry)

var _territory: TerritoryData
var _name: LocalizedLabel
var _description: LocalizedLabel
var _status: LocalizedLabel
var _list: VBoxContainer
var _play: GameButton
var _entries: Array[TerritoryPuzzleEntry] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.045, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(_on_shade_input)
	add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: GamePanel = GamePanel.new()
	panel.custom_minimum_size = Vector2(600.0, 1000.0)
	center.add_child(panel)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)
	_name = LocalizedLabel.new()
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_size_override("font_size", 27)
	layout.add_child(_name)
	_description = LocalizedLabel.new()
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_description)
	_status = LocalizedLabel.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)
	_play = GameButton.new()
	_play.set_localized("ui.map.play_next")
	_play.pressed.connect(_play_next)
	layout.add_child(_play)
	var close: GameButton = GameButton.new()
	close.set_localized("ui.common.close")
	close.pressed.connect(close_panel)
	layout.add_child(close)
	EventBus.language_changed.connect(_on_language_changed)


func _exit_tree() -> void:
	if EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.disconnect(_on_language_changed)
	SceneManager.pop_back_handler(close_panel)


func open(territory: TerritoryData) -> void:
	if territory == null:
		push_error("TerritoryPanel: territory must not be null.")
		queue_free()
		return
	if not visible:
		SceneManager.push_back_handler(close_panel)
	_territory = territory
	_name.set_localized(territory.name_key)
	_description.set_localized(territory.description_key)
	_entries = territory.puzzle_ids.duplicate()
	for child: Node in _list.get_children():
		child.queue_free()
	var unlocked: bool = GameManager.is_territory_unlocked(territory.id)
	_status.set_localized("ui.map.territory_progress", {
		"completed": GameManager.get_territory_completed_puzzle_count(territory),
		"total": _entries.size(),
		"stars": _territory_stars(territory),
		"max_stars": _entries.size() * 3,
	})
	if not unlocked:
		var message: Dictionary = _locked_message(territory)
		_status.set_localized(str(message["key"]), message.get("params", {}) as Dictionary)
	for entry: TerritoryPuzzleEntry in _entries:
		if entry == null:
			continue
		var level: Resource = load(entry.level_resource_path)
		if level == null:
			push_error("TerritoryPanel: cannot load puzzle '%s'." % entry.level_resource_path)
			continue
		var title_key: String = str(level.get("title_key"))
		var row: GameButton = GameButton.new()
		row.set_localized("ui.map.puzzle_row", {
			"title": Localization.translate(title_key),
			"stars": GameManager.get_best_stars(entry.puzzle_id),
		})
		row.disabled = not unlocked
		row.pressed.connect(_on_entry_pressed.bind(entry))
		_list.add_child(row)
	_play.disabled = not unlocked or _entries.is_empty()
	visible = true


func close_panel() -> void:
	visible = false
	SceneManager.pop_back_handler(close_panel)


func _play_next() -> void:
	for entry: TerritoryPuzzleEntry in _entries:
		if entry != null and not GameManager.is_puzzle_completed(entry.puzzle_id):
			play_requested.emit(entry)
			return
	if not _entries.is_empty():
		play_requested.emit(_entries[0])


func get_puzzle_entries() -> Array[TerritoryPuzzleEntry]:
	return _entries.duplicate()


func get_territory() -> TerritoryData:
	return _territory


func _locked_message(territory: TerritoryData) -> Dictionary:
	for prerequisite_id: StringName in territory.previous_territory_ids:
		var previous: TerritoryData = GameManager.get_territory(prerequisite_id)
		if previous == null or GameManager.get_territory_completed_puzzle_count(previous) < previous.puzzle_ids.size():
			return {
				"key": "ui.map.unlock_complete_territory",
				"params": {"territory": Localization.translate(previous.name_key) if previous != null else String(prerequisite_id)},
			}
	var stars_needed: int = maxi(0, territory.minimum_total_stars - GameManager.get_total_stars())
	return {"key": "ui.map.unlock_stars", "params": {"stars": stars_needed}}


func _territory_stars(territory: TerritoryData) -> int:
	var stars: int = 0
	for entry: TerritoryPuzzleEntry in territory.puzzle_ids:
		if entry != null:
			stars += GameManager.get_best_stars(entry.puzzle_id)
	return stars


func _on_language_changed(_locale: String) -> void:
	if _territory != null:
		open(_territory)


func _on_entry_pressed(entry: TerritoryPuzzleEntry) -> void:
	play_requested.emit(entry)


func _on_shade_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_panel()
	elif event is InputEventScreenTouch and event.pressed:
		close_panel()
