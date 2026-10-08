## Procedurally drawn, rotatable circuit cell.
class_name CircuitTile
extends Button

signal rotation_requested
signal detail_requested(label_key: String)

@export var placeholder_tile_texture: Texture2D
@export var placeholder_source_texture: Texture2D
@export var placeholder_target_texture: Texture2D
@export var placeholder_blocker_texture: Texture2D

var _definition: CircuitTileDef
var _queued_rotation_index: int = 0
var _rotation_queue: Array[float] = []
var _queued_visual_degrees: float = 0.0
var _visual_degrees: float = 0.0:
	set(value):
		_visual_degrees = value
		queue_redraw()
var _powered: bool = false
var _glow: float = 0.0
var _highlighted: bool = false
var _shake_x: float = 0.0:
	set(value):
		_shake_x = value
		queue_redraw()
var _long_press_consumed: bool = false
var _long_press_timer: Timer

const EDGES: Array[int] = [
	CircuitLogic.NORTH,
	CircuitLogic.EAST,
	CircuitLogic.SOUTH,
	CircuitLogic.WEST,
]


func _ready() -> void:
	custom_minimum_size = Vector2(88.0, 88.0)
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("normal", _transparent_style())
	add_theme_stylebox_override("hover", _transparent_style())
	add_theme_stylebox_override("pressed", _transparent_style())
	add_theme_stylebox_override("disabled", _transparent_style())
	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.wait_time = 0.4
	_long_press_timer.timeout.connect(_on_long_press_timeout)
	add_child(_long_press_timer)
	pressed.connect(_on_button_pressed)


func configure(definition: CircuitTileDef, rotation_index: int) -> void:
	_definition = definition
	_queued_rotation_index = posmod(rotation_index, 4)
	_queued_visual_degrees = float(_queued_rotation_index) * 90.0
	_visual_degrees = _queued_visual_degrees
	disabled = definition == null or definition.type == CircuitTileDef.TileType.EMPTY
	queue_redraw()


func set_rotation_index(rotation_index: int) -> void:
	var target: int = posmod(rotation_index, 4)
	var remaining: int = posmod(target - _queued_rotation_index, 4)
	while remaining > 0:
		_queued_rotation_index = posmod(_queued_rotation_index + 1, 4)
		_queued_visual_degrees += 90.0
		_rotation_queue.append(_queued_visual_degrees)
		remaining -= 1
	if not _rotation_queue.is_empty() and not has_meta("rotation_active"):
		_play_next_rotation()


func set_powered(value: bool) -> void:
	_powered = value
	var tween: Tween = create_tween()
	tween.tween_property(self, "_glow", 1.0 if value else 0.0, 0.16)


func set_highlighted(value: bool) -> void:
	_highlighted = value
	queue_redraw()


func shake_locked() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "_shake_x", -5.0, 0.035)
	tween.tween_property(self, "_shake_x", 5.0, 0.07)
	tween.tween_property(self, "_shake_x", 0.0, 0.035)


func _gui_input(event: InputEvent) -> void:
	if _definition == null or _definition.label_key.is_empty():
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
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	if _definition == null:
		draw_rect(rect, Color(0.10, 0.13, 0.20), true)
		draw_rect(rect, Color(0.26, 0.31, 0.42), false, 2.0)
		return
	var type: CircuitTileDef.TileType = _definition.type
	var texture: Texture2D
	if type == CircuitTileDef.TileType.SOURCE:
		texture = placeholder_source_texture
	elif type == CircuitTileDef.TileType.TARGET:
		texture = placeholder_target_texture
	elif type == CircuitTileDef.TileType.BLOCKER:
		texture = placeholder_blocker_texture
	else:
		texture = placeholder_tile_texture
	if texture != null:
		draw_texture_rect(texture, rect, false)
	else:
		var base_color: Color = Color(0.10, 0.13, 0.20)
		if type == CircuitTileDef.TileType.BLOCKER:
			base_color = Color(0.17, 0.15, 0.18)
		draw_rect(rect, base_color, true)
		draw_rect(rect, Color(0.26, 0.31, 0.42), false, 2.0)

	if type == CircuitTileDef.TileType.BLOCKER:
		if texture == null:
			var margin: float = size.x * 0.28
			draw_line(Vector2(margin, margin), size - Vector2(margin, margin), Color(0.65, 0.32, 0.35), 5.0, true)
			draw_line(Vector2(size.x - margin, margin), Vector2(margin, size.y - margin), Color(0.65, 0.32, 0.35), 5.0, true)
		return
	if type == CircuitTileDef.TileType.EMPTY:
		return

	var center: Vector2 = size * 0.5
	draw_set_transform(center + Vector2(_shake_x, 0.0), deg_to_rad(_visual_degrees), Vector2.ONE)
	var half: float = size.x * 0.5
	var color: Color = Color(0.35, 0.78, 1.0)
	if type == CircuitTileDef.TileType.SOURCE:
		color = Color(1.0, 0.76, 0.25)
	elif type == CircuitTileDef.TileType.TARGET:
		color = Color(0.49, 1.0, 0.65)
	if _powered:
		color = color.lerp(Color.WHITE, _glow * 0.45)
	var line_width: float = maxf(5.0, size.x * 0.085)
	var reach: float = half * 0.78
	var hub: float = half * 0.16
	var mask: int = CircuitLogic.mask_for_type(type, 0)
	for edge: int in EDGES:
		if (mask & edge) == 0:
			continue
		var end_point: Vector2
		match edge:
			CircuitLogic.NORTH:
				end_point = Vector2(0.0, -reach)
			CircuitLogic.EAST:
				end_point = Vector2(reach, 0.0)
			CircuitLogic.SOUTH:
				end_point = Vector2(0.0, reach)
			_:
				end_point = Vector2(-reach, 0.0)
		draw_line(Vector2.ZERO, end_point, color, line_width, true)
	draw_circle(Vector2.ZERO, hub, color)
	if type == CircuitTileDef.TileType.TARGET:
		draw_arc(Vector2.ZERO, hub * 1.8, 0.0, TAU, 20, color, maxf(2.0, line_width * 0.35), true)
	if _definition.locked:
		var lock_color: Color = Color(0.92, 0.78, 0.42)
		var lock_center: Vector2 = Vector2(half * 0.48, half * 0.48)
		draw_rect(Rect2(lock_center + Vector2(-6.0, -1.0), Vector2(12.0, 9.0)), lock_color, true)
		draw_arc(lock_center + Vector2(0.0, -1.0), 4.0, PI, TAU, 12, lock_color, 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _highlighted:
		draw_rect(rect.grow(-4.0), Color(1.0, 0.88, 0.3), false, 4.0)


func _play_next_rotation() -> void:
	if _rotation_queue.is_empty():
		remove_meta("rotation_active")
		return
	set_meta("rotation_active", true)
	var next_degrees: float = float(_rotation_queue.pop_front())
	var tween: Tween = create_tween()
	tween.tween_property(self, "_visual_degrees", next_degrees, 0.12)
	tween.tween_callback(_play_next_rotation)


func _on_button_pressed() -> void:
	if _long_press_consumed:
		_long_press_consumed = false
		return
	if _definition != null and _definition.locked:
		shake_locked()
		return
	if _definition != null and _definition.type != CircuitTileDef.TileType.EMPTY and _definition.type != CircuitTileDef.TileType.BLOCKER:
		rotation_requested.emit()


func _on_long_press_timeout() -> void:
	if _definition == null or _definition.label_key.is_empty():
		return
	_long_press_consumed = true
	detail_requested.emit(_definition.label_key)


func _transparent_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	return style
