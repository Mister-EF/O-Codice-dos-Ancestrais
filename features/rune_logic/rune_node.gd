## Touch-friendly gate or input node with localized state and explanation.
class_name RuneNode
extends Button

signal node_activated(node_id: StringName)
signal info_requested(node_id: StringName)

@export var placeholder_rune_and: Texture2D
@export var placeholder_rune_or: Texture2D
@export var placeholder_rune_not: Texture2D
@export var placeholder_rune_input_on: Texture2D
@export var placeholder_rune_input_off: Texture2D
@export var placeholder_rune_output: Texture2D

var node_id: StringName = &""
var gate_type: RuneNodeDef.RuneGateType = RuneNodeDef.RuneGateType.INPUT
var _label_key: String = ""
var _value: bool = false
var _locked: bool = false
var _filled: bool = true
var _selected: bool = false
var _highlighted: bool = false
var _long_press_consumed: bool = false
var _long_press_timer: Timer
var _gate_label: LocalizedLabel
var _value_label: LocalizedLabel
var _info_button: LocalizedButton
var _rune_texture: TextureRect


func _ready() -> void:
	custom_minimum_size = Vector2(112.0, 106.0)
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("normal", _style(Color(0.10, 0.14, 0.22)))
	add_theme_stylebox_override("hover", _style(Color(0.13, 0.19, 0.29)))
	add_theme_stylebox_override("pressed", _style(Color(0.08, 0.11, 0.18)))
	add_theme_stylebox_override("disabled", _style(Color(0.10, 0.12, 0.17)))

	var content: VBoxContainer = VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 1)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	_rune_texture = TextureRect.new()
	_rune_texture.custom_minimum_size = Vector2(0.0, 38.0)
	_rune_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rune_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rune_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_rune_texture)
	_gate_label = LocalizedLabel.new()
	_gate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gate_label.add_theme_font_size_override("font_size", 17)
	_gate_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_gate_label)
	_value_label = LocalizedLabel.new()
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value_label.add_theme_font_size_override("font_size", 15)
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_value_label)
	_info_button = LocalizedButton.new()
	_info_button.translation_key = "ui.runes.info"
	_info_button.custom_minimum_size = Vector2(34.0, 30.0)
	_info_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_info_button.pressed.connect(func() -> void: info_requested.emit(node_id))
	content.add_child(_info_button)

	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.wait_time = 0.4
	_long_press_timer.timeout.connect(_on_long_press_timeout)
	add_child(_long_press_timer)
	pressed.connect(_on_pressed)
	refresh()


func configure(definition: RuneNodeDef, value: bool, gate: RuneNodeDef.RuneGateType, filled: bool = true) -> void:
	if definition == null:
		return
	node_id = definition.id
	gate_type = gate
	_label_key = definition.label_key
	_locked = definition.locked
	_filled = filled
	_value = value
	disabled = _locked
	refresh()


func set_state(value: bool, gate: RuneNodeDef.RuneGateType, filled: bool = true) -> void:
	var changed: bool = _value != value
	_value = value
	gate_type = gate
	_filled = filled
	refresh()
	if changed and is_inside_tree():
		var tween: Tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.08)
		tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func set_selected(value: bool) -> void:
	_selected = value
	queue_redraw()


func set_highlighted(value: bool) -> void:
	_highlighted = value
	queue_redraw()


func refresh() -> void:
	if not is_instance_valid(_gate_label):
		return
	var gate_key: String = _gate_key(gate_type)
	var rune_texture: Texture2D = _texture_for_gate(gate_type, _value)
	_rune_texture.texture = rune_texture
	_rune_texture.visible = rune_texture != null
	_gate_label.visible = rune_texture == null or gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT
	if gate_type == RuneNodeDef.RuneGateType.INPUT and not _label_key.is_empty():
		_gate_label.set_localized(_label_key)
	elif gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT and not _filled and not _label_key.is_empty():
		_gate_label.set_localized(_label_key)
	elif gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT and not _filled:
		_gate_label.set_localized("rune.slot.name")
	else:
		_gate_label.set_localized(gate_key)
	if gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT and not _filled:
		_value_label.visible = true
		_value_label.set_localized("ui.runes.choose_gate")
	elif gate_type == RuneNodeDef.RuneGateType.INPUT or gate_type == RuneNodeDef.RuneGateType.OUTPUT:
		_value_label.visible = true
		_value_label.set_localized("ui.runes.value_true" if _value else "ui.runes.value_false")
	else:
		_value_label.visible = true
		_value_label.set_localized("ui.runes.signal_true" if _value else "ui.runes.signal_false")
	_info_button.visible = gate_type != RuneNodeDef.RuneGateType.INPUT and gate_type != RuneNodeDef.RuneGateType.OUTPUT and gate_type != RuneNodeDef.RuneGateType.EMPTY_SLOT
	disabled = _locked
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if gate_type == RuneNodeDef.RuneGateType.INPUT and _locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_long_press_consumed = false
			_long_press_timer.start()
		else:
			_long_press_timer.stop()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_long_press_consumed = false
			_long_press_timer.start()
		else:
			_long_press_timer.stop()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size).grow(-2.0)
	if _selected:
		draw_rect(rect, Color(1.0, 0.82, 0.31), false, 4.0)
	elif _highlighted:
		draw_rect(rect, Color(0.55, 0.88, 1.0), false, 4.0)
	if _locked:
		var center: Vector2 = Vector2(size.x - 15.0, 14.0)
		draw_rect(Rect2(center + Vector2(-5.0, -1.0), Vector2(10.0, 8.0)), Color(0.88, 0.76, 0.45), true)
		draw_arc(center + Vector2(0.0, -1.0), 3.0, PI, TAU, 12, Color(0.88, 0.76, 0.45), 2.0, true)


func _on_pressed() -> void:
	if _long_press_consumed:
		_long_press_consumed = false
		return
	if gate_type == RuneNodeDef.RuneGateType.INPUT and not _locked:
		node_activated.emit(node_id)
	elif gate_type == RuneNodeDef.RuneGateType.EMPTY_SLOT:
		node_activated.emit(node_id)


func _on_long_press_timeout() -> void:
	_long_press_consumed = true
	info_requested.emit(node_id)


func _gate_key(type: RuneNodeDef.RuneGateType) -> String:
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


func _texture_for_gate(type: RuneNodeDef.RuneGateType, value: bool) -> Texture2D:
	match type:
		RuneNodeDef.RuneGateType.INPUT:
			return placeholder_rune_input_on if value else placeholder_rune_input_off
		RuneNodeDef.RuneGateType.AND:
			return placeholder_rune_and
		RuneNodeDef.RuneGateType.OR:
			return placeholder_rune_or
		RuneNodeDef.RuneGateType.NOT:
			return placeholder_rune_not
		RuneNodeDef.RuneGateType.OUTPUT:
			return placeholder_rune_output
	return null


func _style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.37, 0.47, 0.64)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style
