## Data for one node in a rune circuit.
class_name RuneNodeData
extends Resource


## Stable node identifier within a level.
@export var id: StringName = &""

## Gate type represented by this node (RuneGateType.Type enum).
@export var gate_type: int = 0

## IDs of nodes connected to this node's inputs.
@export var input_ids: Array[StringName] = []

## Whether the gate type cannot be changed by the player.
@export var locked: bool = false

## Initial value for input nodes.
@export var initial_value: bool = false