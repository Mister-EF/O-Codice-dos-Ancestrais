## Resolves and launches puzzle levels across the three puzzle mechanics.
class_name PuzzleLauncher
extends RefCounted

const MEMORY_PUZZLE_SCENE: String = "res://features/memory_board/memory_board.tscn"
const CIRCUIT_PUZZLE_SCENE: String = "res://features/circuit_puzzle/circuit_puzzle.tscn"
const RUNE_PUZZLE_SCENE: String = "res://features/rune_logic/rune_puzzle.tscn"

static func launch_puzzle(puzzle_id: String) -> void:
	if puzzle_id.begins_with("memory_"):
		var lvl_path: String = "res://data/puzzles/memory/%s.tres" % puzzle_id
		if ResourceLoader.exists(lvl_path):
			SceneManager.change_scene(MEMORY_PUZZLE_SCENE, {"level_path": lvl_path, "puzzle_id": puzzle_id})
		else:
			push_error("PuzzleLauncher: Level resource not found: " + lvl_path)
	elif puzzle_id.begins_with("circuit_"):
		var lvl_path: String = "res://data/puzzles/circuit/%s.tres" % puzzle_id
		if ResourceLoader.exists(lvl_path):
			SceneManager.change_scene(CIRCUIT_PUZZLE_SCENE, {"level_path": lvl_path, "puzzle_id": puzzle_id})
		else:
			push_error("PuzzleLauncher: Level resource not found: " + lvl_path)
	elif puzzle_id.begins_with("runes_"):
		var lvl_path: String = "res://data/puzzles/runes/%s.tres" % puzzle_id
		if ResourceLoader.exists(lvl_path):
			SceneManager.change_scene(RUNE_PUZZLE_SCENE, {"level_path": lvl_path, "puzzle_id": puzzle_id})
		else:
			push_error("PuzzleLauncher: Level resource not found: " + lvl_path)
	else:
		push_error("PuzzleLauncher: Unknown puzzle id '%s'" % puzzle_id)
