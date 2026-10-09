## Debug launcher scene for Memory Board puzzle standalone testing.
class_name MemoryBoardDebug
extends Control

@onready var _board: MemoryBoard = $MemoryBoard
@onready var _level_selector: OptionButton = $UI/HBox/OptionButton
@onready var _start_button: Button = $UI/HBox/StartButton
@onready var _ui_bar: HBoxContainer = $UI/HBox

var _levels: Array[MemoryBoardLevel] = []

func _ready() -> void:
	_load_levels()
	_start_button.pressed.connect(_on_start_pressed)
	_board.exit_requested.connect(_on_exit_requested)
	if _levels.size() > 0:
		_start_level(0)


func me_ready() -> void:
	pass

func _load_levels() -> void:
	_levels.clear()
	_level_selector.clear()
	for i in range(1, 7):
		var path: String = "res://data/puzzles/memory/memory_0%d.tres" % i
		if ResourceLoader.exists(path):
			var lvl: MemoryBoardLevel = load(path) as MemoryBoardLevel
			if lvl != null:
				_levels.append(lvl)
				_level_selector.add_item("Level %d (%s)" % [i, lvl.id])

func _on_start_pressed() -> void:
	var idx: int = _level_selector.selected
	if idx >= 0 and idx < _levels.size():
		_start_level(idx)

func _start_level(idx: int) -> void:
	_ui_bar.visible = false
	_board.visible = true
	_board.start_level(_levels[idx])

func _on_exit_requested() -> void:
	_board.visible = false
	_ui_bar.visible = true
