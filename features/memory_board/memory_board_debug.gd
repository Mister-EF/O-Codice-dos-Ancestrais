## Temporary standalone level picker; Step 5 can replace this launch flow.
extends Control

const BOARD_SCENE: PackedScene = preload("res://features/memory_board/memory_board.tscn")

var _levels: Array[MemoryBoardLevel] = []
var _board: MemoryBoard


func _ready() -> void:
	for index: int in range(1, 7):
		var path: String = "res://data/puzzles/memory/memory_%02d.tres" % index
		var level: MemoryBoardLevel = load(path) as MemoryBoardLevel
		if level == null:
			push_error("Memory debug launcher: failed to load '%s'." % path)
			continue
		_levels.append(level)
	_build_picker()


func _build_picker() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.055, 0.065, 0.12)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var list: VBoxContainer = VBoxContainer.new()
	list.custom_minimum_size = Vector2(480.0, 0.0)
	list.add_theme_constant_override("separation", 14)
	center.add_child(list)
	var heading: LocalizedLabel = LocalizedLabel.new()
	heading.translation_key = "ui.memory.debug_title"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	list.add_child(heading)
	for level: MemoryBoardLevel in _levels:
		var button: LocalizedButton = LocalizedButton.new()
		button.translation_key = level.title_key
		button.custom_minimum_size = Vector2(0.0, 68.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_launch_level.bind(level))
		list.add_child(button)


func _launch_level(level: MemoryBoardLevel) -> void:
	var root: Node = get_tree().root
	_board = BOARD_SCENE.instantiate() as MemoryBoard
	_board.level_sequence = _levels
	_board.exit_requested.connect(_return_to_picker)
	_board.level_finished.connect(_register_result)
	root.add_child(_board)
	_board.start_level(level)
	hide()


func _return_to_picker() -> void:
	if is_instance_valid(_board):
		_board.queue_free()
	show()


func _register_result(result: PuzzleResult) -> void:
	GameManager.register_puzzle_result(result)
