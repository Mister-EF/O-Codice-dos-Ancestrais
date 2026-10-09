## Development-only level picker and progress-registering host for rune puzzles.
class_name RunePuzzleDebug
extends Control

const PUZZLE_SCENE: PackedScene = preload("res://features/rune_logic/rune_puzzle.tscn")

var _levels: Array[RuneLevel] = []
var _picker_root: CenterContainer
var _picker: VBoxContainer
var _puzzle: RunePuzzle


func _ready() -> void:
	_load_levels()
	_build_picker()


func _load_levels() -> void:
	for index: int in range(1, 11):
		var path: String = "res://data/puzzles/runes/runes_%02d.tres" % index
		var level: RuneLevel = load(path) as RuneLevel
		if level == null:
			push_error("RunePuzzleDebug: unable to load level '%s'." % path)
			return
		_levels.append(level)


func _build_picker() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.045, 0.055, 0.10)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_picker_root = CenterContainer.new()
	_picker_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_picker_root)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500.0, 690.0)
	_picker_root.add_child(panel)
	_picker = VBoxContainer.new()
	_picker.add_theme_constant_override("separation", 8)
	panel.add_child(_picker)
	var title: LocalizedLabel = LocalizedLabel.new()
	title.translation_key = "ui.runes.debug_title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	_picker.add_child(title)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_picker.add_child(scroll)
	var levels_box: VBoxContainer = VBoxContainer.new()
	levels_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	levels_box.add_theme_constant_override("separation", 8)
	scroll.add_child(levels_box)
	for level: RuneLevel in _levels:
		var button: LocalizedButton = LocalizedButton.new()
		button.translation_key = level.title_key
		button.custom_minimum_size = Vector2(0.0, 52.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_start_level.bind(level))
		levels_box.add_child(button)


func _start_level(level: RuneLevel) -> void:
	_puzzle = PUZZLE_SCENE.instantiate() as RunePuzzle
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
