## Touch-first rune gate button with procedural art fallback.
class_name RuneNodeView
extends Button


## Emitted when the node receives a normal tap.
signal node_activated(node_id: StringName)
## Emitted after a 0.4 second press-and-hold.
signal info_requested(node_id: StringName)

## Optional visual slots, replaced by the art team later.
@export var placeholder_rune_and: Texture2D
@export var placeholder_rune_or: Texture2D
@export var placeholder_rune_not: Texture2D
@export var placeholder_rune_input_on: Texture2D
@export var placeholder_rune_input_off: Texture2D
@export var placeholder_rune_output: Texture2D
## Optional rune interaction sound effects.
@export var sfx_toggle: AudioStream
@export var sfx_place: AudioStream
@export var sfx_solved: AudioStream
@export var sfx_error: AudioStream

var node_id: StringName = &""
var gate_type: RuneGateType.Type = RuneGateType.Type.INPUT
var node_value: bool = false
var interactive: bool = true

var _label: Label
var _hold_timer: Timer
var _long_press_fired: bool = false


## Builds the accessible fallback label and long-press timer.
func _ready() -> void:
	custom_minimum_size = Vector2(112.0, 112.0)
	_size_label()
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_hold_timer = Timer.new()
	_hold_timer.one_shot = true
	_hold_timer.wait_time = 0.4
	_hold_timer.timeout.connect(_on_long_press_timeout)
	add_child(_hold_timer)
	pressed.connect(_on_pressed)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	if EventBus.language_changed.is_connected(_refresh_label) == false:
		EventBus.language_changed.connect(_refresh_label)
	_refresh_label()


## Sets the node's identity, gate, state, and tap behavior.
func set_node_state(id: StringName, type: RuneGateType.Type, value: bool, can_interact: bool) -> void:
	node_id = id
	gate_type = type
	node_value = value
	interactive = can_interact
	disabled = false
	_refresh_label()
	queue_redraw()


## Updates the visible glyph label after state or locale changes.
func refresh_locale() -> void:
	_refresh_label()


## Returns the placeholder texture for this node's current gate/state.
func get_placeholder_texture() -> Texture2D:
	match gate_type:
		RuneGateType.Type.AND:
			return placeholder_rune_and
		RuneGateType.Type.OR:
			return placeholder_rune_or
		RuneGateType.Type.NOT:
			return placeholder_rune_not
		RuneGateType.Type.INPUT:
			return placeholder_rune_input_on if node_value else placeholder_rune_input_off
		RuneGateType.Type.OUTPUT:
			return placeholder_rune_output
	return null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			_long_press_fired = false
			_hold_timer.start()
		else:
			_hold_timer.stop()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.pressed:
			_long_press_fired = false
			_hold_timer.start()
		else:
			_hold_timer.stop()


func _draw() -> void:
	var texture: Texture2D = get_placeholder_texture()
	if texture == null:
		var center: Vector2 = size * 0.5
		var radius: float = minf(size.x, size.y) * 0.36
		var active_color: Color = Color(0.22, 0.72, 0.62) if node_value else Color(0.42, 0.47, 0.50)
		draw_circle(center, radius, active_color)
		draw_arc(center, radius, 0.0, TAU, 48, Color(0.92, 0.86, 0.64), 4.0, true)
		draw_string(ThemeDB.fallback_font, center + Vector2(-5.0, 6.0), "1" if node_value else "0", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color.WHITE)


func _on_pressed() -> void:
	if _long_press_fired:
		_long_press_fired = false
		return
	if not interactive:
		info_requested.emit(node_id)
		return
	_play(sfx_toggle if gate_type == RuneGateType.Type.INPUT else sfx_place)
	node_activated.emit(node_id)


func _on_long_press_timeout() -> void:
	_long_press_fired = true
	info_requested.emit(node_id)


func _on_button_down() -> void:
	Haptics.vibrate()
	var pulse: Tween = create_tween()
	pulse.tween_property(self, "scale", Vector2(0.94, 0.94), 0.06)


func _on_button_up() -> void:
	var pulse: Tween = create_tween()
	pulse.tween_property(self, "scale", Vector2.ONE, 0.10)


func _refresh_label(_locale: String = "") -> void:
	if _label == null:
		return
	var key: String = "rune.input.name"
	match gate_type:
		RuneGateType.Type.AND:
			key = "rune.and.name"
		RuneGateType.Type.OR:
			key = "rune.or.name"
		RuneGateType.Type.NOT:
			key = "rune.not.name"
		RuneGateType.Type.OUTPUT:
			key = "rune.output.name"
		RuneGateType.Type.EMPTY_SLOT:
			key = "ui.runes.empty_slot"
	var value_key: String = "ui.runes.true" if node_value else "ui.runes.false"
	if gate_type == RuneGateType.Type.INPUT or gate_type == RuneGateType.Type.OUTPUT:
		_label.text = "%s\n%s" % [Localization.translate(key), Localization.translate(value_key)]
	else:
		_label.text = Localization.translate(key)
	var texture: Texture2D = get_placeholder_texture()
	icon = texture
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	queue_redraw()


func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	if _active_stream == null:
		_active_stream = stream
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _size_label() -> void:
	custom_minimum_size = Vector2(112.0, 112.0)