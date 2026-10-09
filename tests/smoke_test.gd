## Headless Smoke Test — Validates all scenes and resources load and instantiate.
## Run with: godot --headless res://tests/smoke_test.tscn
class_name SmokeTest
extends Node

var _passed: int = 0
var _failed: int = 0

const SCENES: Array[String] = [
	"res://main.tscn",
	"res://ui/main_menu/main_menu.tscn",
	"res://ui/faction_select/faction_select.tscn",
	"res://ui/settings/settings_menu.tscn",
	"res://ui/world_map/world_map.tscn",
	"res://ui/common/confirm_dialog.tscn",
	"res://ui/common/toast_notification.tscn",
	"res://features/circuit_puzzle/circuit_puzzle.tscn",
	"res://features/memory_board/memory_board.tscn",
	"res://features/rune_logic/rune_puzzle.tscn",
]

const RESOURCE_DIRS: Array[String] = [
	"res://data/territories/",
	"res://data/concepts/",
	"res://data/puzzles/memory/",
	"res://data/puzzles/circuit/",
	"res://data/puzzles/runes/",
	"res://data/factions/",
]


func _ready() -> void:
	print("═══ Smoke Test: Scenes and Resources ═══\n")

	_test_scenes()
	_test_resources()
	_test_asset_catalog()

	print("\n── Smoke Test Results: %d passed, %d failed ──" % [_passed, _failed])
	if _failed > 0:
		print("❌ SMOKE TEST FAILED")
		get_tree().quit(1)
	else:
		print("✅ ALL SMOKE TESTS PASSED")
		get_tree().quit(0)


func _test_scenes() -> void:
	print("── Checking PackedScenes ──")
	for path: String in SCENES:
		if not ResourceLoader.exists(path):
			printerr("FAIL: Scene file missing: ", path)
			_failed += 1
			continue

		var scn: Resource = ResourceLoader.load(path)
		if scn is PackedScene:
			var node: Node = (scn as PackedScene).instantiate()
			if node != null:
				print("  ✓ Scene OK: ", path)
				node.free()
				_passed += 1
			else:
				printerr("FAIL: Could not instantiate scene: ", path)
				_failed += 1
		else:
			printerr("FAIL: Loaded resource is not a PackedScene: ", path)
			_failed += 1


func _test_resources() -> void:
	print("\n── Checking Resource Directories ──")
	for dir_path: String in RESOURCE_DIRS:
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir == null:
			printerr("FAIL: Directory cannot be opened: ", dir_path)
			_failed += 1
			continue

		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		var count: int = 0
		while file_name != "":
			if file_name.ends_with(".tres"):
				var full_path: String = dir_path + file_name
				var res: Resource = ResourceLoader.load(full_path)
				if res != null:
					_passed += 1
					count += 1
				else:
					printerr("FAIL: Resource failed to load: ", full_path)
					_failed += 1
			file_name = dir.get_next()
		dir.list_dir_end()
		print("  ✓ Checked %d resources in %s" % [count, dir_path])


func _test_asset_catalog() -> void:
	print("\n── Checking Asset Catalog ──")
	var catalog_path: String = "res://data/asset_catalog.tres"
	if ResourceLoader.exists(catalog_path):
		var cat: Resource = ResourceLoader.load(catalog_path)
		if cat != null:
			print("  ✓ AssetCatalog OK: ", catalog_path)
			_passed += 1
		else:
			printerr("FAIL: AssetCatalog failed to load")
			_failed += 1
	else:
		printerr("FAIL: AssetCatalog missing")
		_failed += 1
