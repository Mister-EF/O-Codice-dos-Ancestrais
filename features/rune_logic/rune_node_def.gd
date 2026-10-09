## One node in an authored Boolean gate network.
class_name RuneNodeDef
extends Resource

enum RuneGateType { INPUT, AND, OR, NOT, OUTPUT, EMPTY_SLOT }

@export var id: StringName = &""
@export var gate_type: RuneGateType = RuneGateType.INPUT
@export var input_node_ids: Array[StringName] = []
@export var locked: bool = false
@export var initial_value: bool = false
@export var label_key: String = ""
@export var layout_position: Vector2 = Vector2.ZERO
