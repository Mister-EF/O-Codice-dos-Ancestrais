## Procedural circuit wire layer with redundant value cues.
class_name RuneWireView
extends Control


var level: RuneLevel
var node_positions: Dictionary[StringName, Vector2] = {}
var node_values: Dictionary[StringName, bool] = {}


## Sets wire endpoints and values, then redraws the circuit.
func set_circuit(source_level: RuneLevel, positions: Dictionary[StringName, Vector2], values: Dictionary[StringName, bool]) -> void:
	level = source_level
	node_positions = positions.duplicate()
	node_values = values.duplicate()
	queue_redraw()


func _draw() -> void:
	if level == null:
		return
	for node_data: RuneNodeData in level.nodes:
		if not node_positions.has(node_data.id):
			continue
		var target: Vector2 = node_positions[node_data.id]
		for input_id: StringName in node_data.input_ids:
			if not node_positions.has(input_id):
				continue
			var source: Vector2 = node_positions[input_id]
			var value: bool = node_values.get(input_id, false)
			var color: Color = Color(0.22, 0.78, 0.62) if value else Color(0.56, 0.60, 0.62)
			var width: float = 7.0 if value else 4.0
			_draw_segment(source, target, color, width, value)


func _draw_segment(start: Vector2, finish: Vector2, color: Color, line_width: float, solid: bool) -> void:
	if solid:
		draw_line(start, finish, color, line_width, true)
		return
	var distance: float = start.distance_to(finish)
	var direction: Vector2 = (finish - start).normalized()
	var segment_start: float = 0.0
	while segment_start < distance:
		var segment_end: float = minf(segment_start + 12.0, distance)
		draw_line(start + direction * segment_start, start + direction * segment_end, color, line_width, true)
		segment_start += 22.0