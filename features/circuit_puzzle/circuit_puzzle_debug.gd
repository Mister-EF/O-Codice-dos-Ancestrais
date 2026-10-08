## Standalone level picker and host for circuit puzzle testing.
class_name CircuitPuzzleDebug
extends Control

const PUZZLE_SCENE: PackedScene = preload("res://features/circuit_puzzle/circuit_puzzle.tscn")

var _levels: Array[CircuitLevel] = []
var _picker: VBoxContainer
var _picker_root: CenterContainer
var _puzzle: CircuitPuzzle


func _ready() -> void:
	_load_levels()
	_build_picker()


func _load_levels() -> void:
	for index: int in range(1, 9):
		var path: String = "res://data/puzzles/circuit/circuit_%02d.tres" % index
		var level: CircuitLevel = load(path) as CircuitLevel
		if level == null:
			push_error("CircuitPuzzleDebug: unable to load level '%s'." % path)
			return
		_levels.append(level)


func _build_picker() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.045, 0.06, 0.105)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_picker_root = center
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500.0, 620.0)
	center.add_child(panel)
	_picker = VBoxContainer.new()
	_picker.add_theme_constant_override("separation", 12)
	panel.add_child(_picker)
	var title: LocalizedLabel = LocalizedLabel.new()
	title.translation_key = "ui.circuit.debug_title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	_picker.add_child(title)
	for level: CircuitLevel in _levels:
		var button: LocalizedButton = LocalizedButton.new()
		button.translation_key = level.title_key
		button.custom_minimum_size = Vector2(0.0, 54.0)
		button.pressed.connect(_start_level.bind(level))
		_picker.add_child(button)


func _start_level(level: CircuitLevel) -> void:
	_puzzle = PUZZLE_SCENE.instantiate() as CircuitPuzzle
	_puzzle.level_sequence = _levels
	_puzzle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_puzzle.level_finished.connect(_on_level_finished)
	_puzzle.exit_requested.connect(_on_exit_requested)
	add_child(_puzzle)
	_picker_root.visible = false
	_puzzle.start_level(level)


func _on_level_finished(result: PuzzleResult) -> void:
	GameManager.register_puzzle_result(result)


func _on_exit_requested() -> void:
	if is_instance_valid(_puzzle):
		_puzzle.queue_free()
		_puzzle = null
	_picker_root.visible = true
