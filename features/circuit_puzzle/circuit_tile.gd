## CircuitTile — UI Control representing an individual tile on the circuit grid.
## Handles touch/click, rotation tweens, locked shakes, long-press inspection,
## and procedural drawing when placeholder textures are null.
class_name CircuitTile
extends Control


## Emitted when the tile is tapped (requests 90 deg clockwise rotation).
signal tile_tapped(cell: Vector2i)

## Emitted when a tile is held for ~0.4s to inspect educational concept info.
signal tile_long_pressed(cell: Vector2i, label_key: String)


# ── Asset Placeholder Exports ────────────────────────────────────────────────
@export var placeholder_tile_texture: Texture2D
@export var placeholder_source_texture: Texture2D
@export var placeholder_target_texture: Texture2D
@export var placeholder_blocker_texture: Texture2D

# ── Tile State ───────────────────────────────────────────────────────────────
var cell_coord: Vector2i = Vector2i.ZERO
var tile_type: CircuitTileDef.CircuitTileType = CircuitTileDef.CircuitTileType.EMPTY
var rotation_index: int = 0
var is_locked: bool = false
var label_key: String = ""
var is_powered: bool = false

# Visual rotation tracking (in degrees, can exceed 360 to smoothly accumulate rapid taps)
var _visual_target_rotation: float = 0.0
var _current_visual_rotation: float = 0.0
var _rotation_tween: Tween
var _shake_tween: Tween
var _glow_tween: Tween

# Long-press detection
const LONG_PRESS_DURATION: float = 0.4
var _press_timer: float = 0.0
var _is_pressing: bool = false
var _press_pos: Vector2 = Vector2.ZERO
var _drag_threshold: float = 20.0
var _long_press_triggered: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(88, 88)
	pivot_offset = size / 2.0
	resized.connect(_on_resized)


func _on_resized() -> void:
	pivot_offset = size / 2.0
	queue_redraw()


func _process(delta: float) -> void:
	if _is_pressing and not _long_press_triggered:
		_press_timer += delta
		if _press_timer >= LONG_PRESS_DURATION:
			_long_press_triggered = true
			if label_key != "":
				tile_long_pressed.emit(cell_coord, label_key)
				Haptics.vibrate(60)


## Configures the tile from logic state.
func setup(
	p_cell: Vector2i,
	p_type: CircuitTileDef.CircuitTileType,
	p_rot_index: int,
	p_locked: bool,
	p_label_key: String,
	p_powered: bool
) -> void:
	cell_coord = p_cell
	tile_type = p_type
	rotation_index = p_rot_index
	is_locked = p_locked
	label_key = p_label_key
	is_powered = p_powered

	_visual_target_rotation = float(rotation_index * 90)
	_current_visual_rotation = _visual_target_rotation
	queue_redraw()


## Called when the tile is rotated logically. Advances visual rotation tween.
func animate_rotation(new_rotation_index: int) -> void:
	rotation_index = new_rotation_index
	_visual_target_rotation += 90.0

	if _rotation_tween and _rotation_tween.is_valid():
		_rotation_tween.kill()

	_rotation_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_rotation_tween.tween_property(self, "_current_visual_rotation", _visual_target_rotation, 0.18)
	_rotation_tween.parallel().tween_property(self, "scale", Vector2(1.08, 1.08), 0.09)
	_rotation_tween.tween_property(self, "scale", Vector2.ONE, 0.09)
	_rotation_tween.step_finished.connect(func(_idx: int) -> void: queue_redraw())
	_rotation_tween.finished.connect(func() -> void:
		_current_visual_rotation = fmod(_current_visual_rotation, 360.0)
		_visual_target_rotation = _current_visual_rotation
		queue_redraw()
	)


## Updates powered state with optional animated glow.
func set_powered(powered: bool, animated: bool = true) -> void:
	if is_powered == powered:
		return
	is_powered = powered

	if animated:
		if _glow_tween and _glow_tween.is_valid():
			_glow_tween.kill()
		_glow_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if is_powered:
			scale = Vector2(1.1, 1.1)
			_glow_tween.tween_property(self, "scale", Vector2.ONE, 0.25)
	queue_redraw()


## Triggers short shake visual effect when user taps a locked tile.
func play_shake() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	var original_pos: Vector2 = position
	_shake_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shake_tween.tween_property(self, "position:x", original_pos.x - 6.0, 0.04)
	_shake_tween.tween_property(self, "position:x", original_pos.x + 6.0, 0.04)
	_shake_tween.tween_property(self, "position:x", original_pos.x - 4.0, 0.04)
	_shake_tween.tween_property(self, "position:x", original_pos.x + 4.0, 0.04)
	_shake_tween.tween_property(self, "position:x", original_pos.x, 0.04)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_pressing = true
				_press_timer = 0.0
				_press_pos = mb.position
				_long_press_triggered = false
			else:
				if _is_pressing and not _long_press_triggered:
					# Normal tap detected
					_handle_tap()
				_is_pressing = false

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if _is_pressing and mm.position.distance_to(_press_pos) > _drag_threshold:
			_is_pressing = false # Cancel long-press on drag

	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_is_pressing = true
			_press_timer = 0.0
			_press_pos = st.position
			_long_press_triggered = false
		else:
			if _is_pressing and not _long_press_triggered:
				_handle_tap()
			_is_pressing = false

	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		if _is_pressing and sd.position.distance_to(_press_pos) > _drag_threshold:
			_is_pressing = false


func _handle_tap() -> void:
	if is_locked or tile_type == CircuitTileDef.CircuitTileType.EMPTY or tile_type == CircuitTileDef.CircuitTileType.BLOCKER:
		if is_locked and tile_type != CircuitTileDef.CircuitTileType.EMPTY:
			play_shake()
			Haptics.vibrate(40)
		return

	Haptics.vibrate(30)
	tile_tapped.emit(cell_coord)


# ── Procedural Drawing ───────────────────────────────────────────────────────

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var center: Vector2 = size / 2.0
	var tile_rad: float = minf(size.x, size.y) * 0.46

	# 1. Background tile container
	var bg_color: Color = Color(0.08, 0.12, 0.18, 0.85)
	if is_powered:
		bg_color = Color(0.12, 0.22, 0.32, 0.95)
	if tile_type == CircuitTileDef.CircuitTileType.BLOCKER:
		bg_color = Color(0.2, 0.08, 0.08, 0.9)

	draw_rect(rect, bg_color, true)
	var border_color: Color = Color(0.2, 0.35, 0.45, 0.5)
	if is_powered:
		border_color = Color(0.2, 0.75, 0.95, 0.8)
	draw_rect(rect, border_color, false, 2.0)

	if tile_type == CircuitTileDef.CircuitTileType.EMPTY:
		return

	# If placeholder texture is provided, draw it
	var texture_to_draw: Texture2D = null
	match tile_type:
		CircuitTileDef.CircuitTileType.SOURCE:
			texture_to_draw = placeholder_source_texture
		CircuitTileDef.CircuitTileType.TARGET:
			texture_to_draw = placeholder_target_texture
		CircuitTileDef.CircuitTileType.BLOCKER:
			texture_to_draw = placeholder_blocker_texture
		_:
			texture_to_draw = placeholder_tile_texture

	if texture_to_draw != null:
		draw_texture_rect(texture_to_draw, rect, false)
		_draw_locked_icon(center, tile_rad)
		return

	# Draw procedural lines based on tile type and visual rotation
	var line_width: float = maxf(6.0, size.x * 0.1)
	var wire_color: Color = Color(0.3, 0.45, 0.6, 0.8)
	var core_color: Color = Color(0.5, 0.7, 0.9, 0.9)
	if is_powered:
		wire_color = Color(0.1, 0.85, 1.0, 1.0)
		core_color = Color(0.8, 0.98, 1.0, 1.0)

	# Special cases: Blocker
	if tile_type == CircuitTileDef.CircuitTileType.BLOCKER:
		var blk_col: Color = Color(0.8, 0.2, 0.2, 0.85)
		draw_line(Vector2(size.x * 0.25, size.y * 0.25), Vector2(size.x * 0.75, size.y * 0.75), blk_col, line_width * 1.2)
		draw_line(Vector2(size.x * 0.75, size.y * 0.25), Vector2(size.x * 0.25, size.y * 0.75), blk_col, line_width * 1.2)
		return

	# Rotate canvas for rotatable wires
	draw_set_transform(center, deg_to_rad(_current_visual_rotation), Vector2.ONE)

	var north_pt: Vector2 = Vector2(0, -center.y)
	var east_pt: Vector2 = Vector2(center.x, 0)
	var south_pt: Vector2 = Vector2(0, center.y)
	var west_pt: Vector2 = Vector2(-center.x, 0)

	match tile_type:
		CircuitTileDef.CircuitTileType.STRAIGHT:
			# North to South line
			draw_line(north_pt, south_pt, wire_color, line_width)
			draw_line(north_pt, south_pt, core_color, line_width * 0.4)

		CircuitTileDef.CircuitTileType.CORNER:
			# North to East curve/lines
			draw_line(north_pt, Vector2.ZERO, wire_color, line_width)
			draw_line(Vector2.ZERO, east_pt, wire_color, line_width)
			draw_line(north_pt, Vector2.ZERO, core_color, line_width * 0.4)
			draw_line(Vector2.ZERO, east_pt, core_color, line_width * 0.4)
			draw_circle(Vector2.ZERO, line_width * 0.5, wire_color)

		CircuitTileDef.CircuitTileType.T_JUNCTION:
			# North, East, South
			draw_line(north_pt, south_pt, wire_color, line_width)
			draw_line(Vector2.ZERO, east_pt, wire_color, line_width)
			draw_line(north_pt, south_pt, core_color, line_width * 0.4)
			draw_line(Vector2.ZERO, east_pt, core_color, line_width * 0.4)
			draw_circle(Vector2.ZERO, line_width * 0.6, wire_color)

		CircuitTileDef.CircuitTileType.CROSS:
			# All 4 directions
			draw_line(north_pt, south_pt, wire_color, line_width)
			draw_line(west_pt, east_pt, wire_color, line_width)
			draw_line(north_pt, south_pt, core_color, line_width * 0.4)
			draw_line(west_pt, east_pt, core_color, line_width * 0.4)
			draw_circle(Vector2.ZERO, line_width * 0.7, wire_color)

		CircuitTileDef.CircuitTileType.SOURCE:
			# Opens North
			draw_line(Vector2.ZERO, north_pt, wire_color, line_width)
			draw_line(Vector2.ZERO, north_pt, core_color, line_width * 0.4)
			# Energy generator node circle
			var src_col: Color = Color(0.2, 1.0, 0.4, 1.0)
			draw_circle(Vector2.ZERO, tile_rad * 0.6, src_col)
			draw_circle(Vector2.ZERO, tile_rad * 0.35, Color(1, 1, 1, 0.9))

		CircuitTileDef.CircuitTileType.TARGET:
			# Opens North
			draw_line(Vector2.ZERO, north_pt, wire_color, line_width)
			draw_line(Vector2.ZERO, north_pt, core_color, line_width * 0.4)
			# Target node diamond / ring
			var tgt_col: Color = Color(1.0, 0.45, 0.15, 1.0) if not is_powered else Color(1.0, 0.9, 0.2, 1.0)
			draw_circle(Vector2.ZERO, tile_rad * 0.6, tgt_col)
			draw_circle(Vector2.ZERO, tile_rad * 0.4, Color(0.1, 0.1, 0.15, 0.9))
			if is_powered:
				draw_circle(Vector2.ZERO, tile_rad * 0.25, Color(1, 1, 1, 0.95))

	# Reset transform
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Draw locked visual icon (if locked and not source/target/blocker)
	_draw_locked_icon(center, tile_rad)

	# Draw concept indicator dot if label_key exists
	if label_key != "":
		var dot_color: Color = Color(0.3, 0.8, 1.0, 0.9)
		draw_circle(Vector2(size.x - 14, 14), 5.0, dot_color)


func _draw_locked_icon(center: Vector2, tile_rad: float) -> void:
	if not is_locked:
		return
	if tile_type == CircuitTileDef.CircuitTileType.SOURCE or tile_type == CircuitTileDef.CircuitTileType.TARGET:
		return # Source and Target nodes have intrinsic meaning; only show padlock on connectors

	# Distinct localized-free padlock icon in corner
	var lock_pos: Vector2 = Vector2(16, 16)
	var body_rect: Rect2 = Rect2(lock_pos.x - 7, lock_pos.y - 2, 14, 11)
	draw_rect(body_rect, Color(0.85, 0.75, 0.2, 0.9), true)
	draw_arc(Vector2(lock_pos.x, lock_pos.y - 3), 5.0, PI, 2.0 * PI, 8, Color(0.85, 0.75, 0.2, 0.9), 2.5)
