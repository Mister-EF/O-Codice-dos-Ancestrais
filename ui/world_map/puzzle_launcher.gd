## Hosts one puzzle scene and registers results before returning to the map.
class_name PuzzleLauncher
extends Control

signal closed

const MEMORY_SCENE: PackedScene = preload("res://features/memory_board/memory_board.tscn")
const CIRCUIT_SCENE: PackedScene = preload("res://features/circuit_puzzle/circuit_puzzle.tscn")
const RUNES_SCENE: PackedScene = preload("res://features/rune_logic/rune_puzzle.tscn")

var _entry: TerritoryPuzzleEntry
var _territory_entries: Array[TerritoryPuzzleEntry] = []
var _puzzle_root: Control


func launch(entry: TerritoryPuzzleEntry, territory_entries: Array[TerritoryPuzzleEntry]) -> void:
	_entry = entry
	_territory_entries = territory_entries.duplicate()


func _ready() -> void:
	SceneManager.push_back_handler(_return_to_map)
	if _entry == null:
		push_error("PuzzleLauncher: launch() must be called before adding the host to the tree.")
		return
	var level: Resource = load(_entry.level_resource_path)
	if level == null:
		push_error("PuzzleLauncher: failed to load '%s'." % _entry.level_resource_path)
		_return_to_map()
		return
	match _entry.puzzle_type:
		TerritoryPuzzleEntry.PuzzleType.MEMORY:
			_launch_memory(level as MemoryBoardLevel)
		TerritoryPuzzleEntry.PuzzleType.CIRCUIT:
			_launch_circuit(level as CircuitLevel)
		TerritoryPuzzleEntry.PuzzleType.RUNES:
			_launch_runes(level as RuneLevel)


func _launch_memory(level: MemoryBoardLevel) -> void:
	if level == null:
		push_error("PuzzleLauncher: memory entry references a non-memory resource.")
		_return_to_map()
		return
	var board: MemoryBoard = MEMORY_SCENE.instantiate() as MemoryBoard
	var sequence: Array[MemoryBoardLevel] = []
	for entry: TerritoryPuzzleEntry in _territory_entries:
		if entry.puzzle_type == TerritoryPuzzleEntry.PuzzleType.MEMORY:
			var next_level: MemoryBoardLevel = load(entry.level_resource_path) as MemoryBoardLevel
			if next_level != null:
				sequence.append(next_level)
	board.level_sequence = sequence
	board.level_finished.connect(_on_level_finished)
	board.exit_requested.connect(_return_to_map)
	board.start_level(level)
	_attach_puzzle(board)


func _launch_circuit(level: CircuitLevel) -> void:
	if level == null:
		push_error("PuzzleLauncher: circuit entry references a non-circuit resource.")
		_return_to_map()
		return
	var puzzle: CircuitPuzzle = CIRCUIT_SCENE.instantiate() as CircuitPuzzle
	var sequence: Array[CircuitLevel] = []
	for entry: TerritoryPuzzleEntry in _territory_entries:
		if entry.puzzle_type == TerritoryPuzzleEntry.PuzzleType.CIRCUIT:
			var next_level: CircuitLevel = load(entry.level_resource_path) as CircuitLevel
			if next_level != null:
				sequence.append(next_level)
	puzzle.level_sequence = sequence
	puzzle.level_finished.connect(_on_level_finished)
	puzzle.exit_requested.connect(_return_to_map)
	puzzle.start_level(level)
	_attach_puzzle(puzzle)


func _launch_runes(level: RuneLevel) -> void:
	if level == null:
		push_error("PuzzleLauncher: rune entry references a non-rune resource.")
		_return_to_map()
		return
	var puzzle: RunePuzzle = RUNES_SCENE.instantiate() as RunePuzzle
	var sequence: Array[RuneLevel] = []
	for entry: TerritoryPuzzleEntry in _territory_entries:
		if entry.puzzle_type == TerritoryPuzzleEntry.PuzzleType.RUNES:
			var next_level: RuneLevel = load(entry.level_resource_path) as RuneLevel
			if next_level != null:
				sequence.append(next_level)
	puzzle.level_sequence = sequence
	puzzle.level_finished.connect(_on_level_finished)
	puzzle.exit_requested.connect(_return_to_map)
	puzzle.start_level(level)
	_attach_puzzle(puzzle)


func _attach_puzzle(puzzle: Control) -> void:
	_puzzle_root = puzzle
	puzzle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(puzzle)


func _on_level_finished(result: PuzzleResult) -> void:
	GameManager.register_puzzle_result(result)


func _return_to_map() -> void:
	SceneManager.pop_back_handler(_return_to_map)
	closed.emit()
	queue_free()
