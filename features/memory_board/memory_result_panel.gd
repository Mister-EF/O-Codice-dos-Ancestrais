## End-of-level UI that communicates actions only through signals.
class_name MemoryResultPanel
extends Control

signal retry_requested
signal next_requested
signal back_to_map_requested

var _title: LocalizedLabel
var _stars: LocalizedLabel
var _moves: LocalizedLabel
var _time: LocalizedLabel
var _hints: LocalizedLabel
var _retry: LocalizedButton
var _next: LocalizedButton
var _back: LocalizedButton
var _result: PuzzleResult
var _has_next: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.07, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(540.0, 460.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 15)
	panel.add_child(layout)
	_title = LocalizedLabel.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 30)
	layout.add_child(_title)
	_stars = LocalizedLabel.new()
	_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stars.add_theme_font_size_override("font_size", 26)
	layout.add_child(_stars)
	_moves = LocalizedLabel.new()
	layout.add_child(_moves)
	_time = LocalizedLabel.new()
	layout.add_child(_time)
	_hints = LocalizedLabel.new()
	layout.add_child(_hints)
	var buttons: VBoxContainer = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	layout.add_child(buttons)
	_retry = LocalizedButton.new()
	_retry.translation_key = "ui.memory.retry"
	_retry.pressed.connect(func() -> void: retry_requested.emit())
	buttons.add_child(_retry)
	_next = LocalizedButton.new()
	_next.translation_key = "ui.memory.next"
	_next.pressed.connect(func() -> void: next_requested.emit())
	buttons.add_child(_next)
	_back = LocalizedButton.new()
	_back.translation_key = "ui.memory.back_to_map"
	_back.pressed.connect(func() -> void: back_to_map_requested.emit())
	buttons.add_child(_back)
	EventBus.language_changed.connect(_on_language_changed)
	visible = false


func _exit_tree() -> void:
	if EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.disconnect(_on_language_changed)


func show_result(result: PuzzleResult, has_next: bool) -> void:
	_result = result
	_has_next = has_next
	visible = true
	_refresh()


func _on_language_changed(_locale: String) -> void:
	_refresh()


func _refresh() -> void:
	if _result == null or not is_instance_valid(_title):
		return
	var title_key: String = "ui.memory.level_complete" if _result.completed else "ui.memory.level_failed"
	_title.set_localized(title_key)
	var stars_display: String = "★".repeat(_result.stars) + "☆".repeat(3 - _result.stars)
	_stars.set_localized("ui.memory.stars_result", {"stars": stars_display})
	_moves.set_localized("ui.memory.result_moves", {"count": _result.moves})
	_time.set_localized("ui.memory.result_time", {"time": _format_time(_result.time_seconds)})
	_hints.set_localized("ui.memory.result_hints", {"count": _result.hints_used})
	_next.visible = _has_next and _result.completed


func _format_time(seconds: float) -> String:
	var whole_seconds: int = floori(seconds)
	return "%02d:%02d" % [floori(float(whole_seconds) / 60.0), whole_seconds % 60]


func _panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.11, 0.19, 0.98)
	style.border_color = Color(0.55, 0.62, 0.82)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 22.0
	return style
