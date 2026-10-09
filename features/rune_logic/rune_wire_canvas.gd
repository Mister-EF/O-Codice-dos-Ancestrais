## Procedurally draws Boolean connections with color and shape cues.
class_name RuneWireCanvas
extends Control

var _level: RuneLevel
var _nodes: Dictionary[StringName, RuneNode] = {}
var _values: Dictionary[StringName, bool] = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func configure(level: RuneLevel, nodes: Dictionary[StringName, RuneNode], values: Dictionary[StringName, bool]) -> void:
	_level = level
	_nodes = nodes
	_values = values
	queue_redraw()


func _draw() -> void:
	if _level == null:
		return
	for definition: RuneNodeDef in _level.nodes:
		if not _nodes.has(definition.id):
			continue
		var destination: RuneNode = _nodes[definition.id]
		for source_id: StringName in definition.input_node_ids:
			if not _nodes.has(source_id):
				continue
			var source: RuneNode = _nodes[source_id]
			var start: Vector2 = source.position + Vector2(source.size.x, source.size.y * 0.5)
			var finish: Vector2 = destination.position + Vector2(0.0, destination.size.y * 0.5)
			var signal_value: bool = _values.get(source_id, false)
			var color: Color = Color(0.35, 0.95, 0.65) if signal_value else Color(0.86, 0.43, 0.48)
			var thickness: float = 5.0 if signal_value else 2.5
			var mid_x: float = (start.x + finish.x) * 0.5
			if signal_value:
				draw_line(start, finish, Color(0.11, 0.16, 0.24), thickness + 3.0, true)
				draw_line(start, finish, color, thickness, true)
			else:
				_draw_dashed_line(start, Vector2(mid_x, start.y), color, thickness)
				_draw_dashed_line(Vector2(mid_x, start.y), Vector2(mid_x, finish.y), color, thickness)
				_draw_dashed_line(Vector2(mid_x, finish.y), finish, color, thickness)
			var midpoint: Vector2 = (start + finish) * 0.5
			var cue: String = Localization.translate("ui.runes.wire_true" if signal_value else "ui.runes.wire_false")
			draw_string(ThemeDB.fallback_font, midpoint + Vector2(-6.0, -5.0), cue, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color.WHITE)


func _draw_dashed_line(start: Vector2, finish: Vector2, color: Color, width: float) -> void:
	var distance: float = start.distance_to(finish)
	if distance <= 0.0:
		return
	var direction: Vector2 = (finish - start) / distance
	var segment: float = 8.0
	var gap: float = 5.0
	var travelled: float = 0.0
	while travelled < distance:
		var end_distance: float = minf(travelled + segment, distance)
		draw_line(start + direction * travelled, start + direction * end_distance, color, width, true)
		travelled += segment + gap
