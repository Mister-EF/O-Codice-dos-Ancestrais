## Reference to one puzzle level and the scene family that hosts it.
class_name TerritoryPuzzleEntry
extends Resource

enum PuzzleType { MEMORY, CIRCUIT, RUNES }

@export var puzzle_id: String = ""
@export var puzzle_type: PuzzleType = PuzzleType.MEMORY
@export_file("*.tres") var level_resource_path: String = ""
