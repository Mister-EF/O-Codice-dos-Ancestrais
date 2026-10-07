## CircuitDebug — Standalone harness for testing all Circuit Puzzle levels.
## Provides level selection, auto-solve, language toggle, and live state monitoring.
class_name CircuitDebug
extends Control


@onready var _puzzle_view: CircuitPuzzle = $CircuitPuzzle
@onready var _level_select: OptionButton = $DebugUI/TopBar/LevelSelect
@onready var _solve_btn: Button = $DebugUI/TopBar/SolveBtn
@onready var _lang_btn: Button = $DebugUI/TopBar/LangBtn

var _level_paths: Array[String] = [
	"res://data/puzzles/circuit/circuit_01.tres",
	"res://data/puzzles/circuit/circuit_02.tres",
	"res://data/puzzles/circuit/circuit_03.tres",
	"res://data/puzzles/circuit/circuit_04.tres",
	"res://data/puzzles/circuit/circuit_05.tres",
	"res://data/puzzles/circuit/circuit_06.tres",
	"res://data/puzzles/circuit/circuit_07.tres",
	"res://data/puzzles/circuit/circuit_08.tres",
]

var _loaded_levels: Array[CircuitLevel] = []


func _ready() -> void:
	_load_all_levels()
	_setup_ui()
	if not _loaded_levels.is_empty():
		_puzzle_view.start_level(_loaded_levels[0])


func _load_all_levels() -> void:
	for path: String in _level_paths:
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is CircuitLevel:
				_loaded_levels.append(res as CircuitLevel)


func _setup_ui() -> void:
	_level_select.clear()
	for i: int in range(_loaded_levels.size()):
		var lvl: CircuitLevel = _loaded_levels[i]
		_level_select.add_item(lvl.id + " (" + str(lvl.grid_columns) + "x" + str(lvl.grid_rows) + ")", i)

	_level_select.item_selected.connect(_on_level_selected)
	_solve_btn.pressed.connect(_on_solve_pressed)
	_lang_btn.pressed.connect(_on_lang_toggle_pressed)

	_puzzle_view.exit_requested.connect(func() -> void:
		print("CircuitDebug: Exit requested.")
	)
	_puzzle_view.level_finished.connect(func(res: PuzzleResult) -> void:
		print("CircuitDebug: Level finished with ", res.stars, " stars!")
	)


func _on_level_selected(index: int) -> void:
	if index >= 0 and index < _loaded_levels.size():
		_puzzle_view.start_level(_loaded_levels[index])


func _on_solve_pressed() -> void:
	var idx: int = _level_select.selected
	if idx < 0 or idx >= _loaded_levels.size():
		return
	var lvl: CircuitLevel = _loaded_levels[idx]
	for def: CircuitTileDef in lvl.tiles:
		def.rotation_index = def.solution_rotation
	_puzzle_view.start_level(lvl)


func _on_lang_toggle_pressed() -> void:
	var current: String = Localization.get_language()
	var next_lang: String = "pt_BR" if current == "en" else "en"
	Localization.set_language(next_lang)
