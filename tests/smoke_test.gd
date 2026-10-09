## Headless smoke test for scene/resource references and territory puzzle coverage.
## Run with: godot --headless -s res://tests/smoke_test.gd
extends SceneTree

var _errors: int = 0
var _scene_count: int = 0
var _resource_count: int = 0
var _script_count: int = 0


func _init() -> void:
	call_deferred("_run_smoke_test")


func _run_smoke_test() -> void:
	await process_frame
	_scan_directory("res://")
	_validate_territories()
	if _errors > 0:
		push_error("Smoke test failed with %d error(s)." % _errors)
		quit(1)
	else:
		print("Smoke test passed: %d scenes, %d scripts, %d resources, and all territory puzzle references loaded." % [
			_scene_count,
			_script_count,
			_resource_count,
		])
		quit(0)


func _scan_directory(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		_fail("Cannot open directory '%s'." % path)
		return
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		if file_name.begins_with("."):
			file_name = directory.get_next()
			continue
		var child_path: String = path.path_join(file_name)
		if directory.current_is_dir():
			_scan_directory(child_path)
		elif file_name.ends_with(".tscn"):
			_validate_scene(child_path)
		elif file_name.ends_with(".tres"):
			_validate_resource(child_path)
		elif file_name.ends_with(".gd"):
			_validate_script(child_path)
		file_name = directory.get_next()
	directory.list_dir_end()


func _validate_scene(path: String) -> void:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		_fail("Scene '%s' failed to load." % path)
		return
	var instance: Node = packed.instantiate()
	if instance == null:
		_fail("Scene '%s' failed to instantiate." % path)
		return
	instance.free()
	_scene_count += 1


func _validate_resource(path: String) -> void:
	var resource: Resource = load(path)
	if resource == null:
		_fail("Resource '%s' failed to load." % path)
	else:
		_resource_count += 1


func _validate_script(path: String) -> void:
	var script: GDScript = load(path) as GDScript
	if script == null or not script.can_instantiate():
		_fail("Script '%s' failed to compile." % path)
	else:
		_script_count += 1


func _validate_territories() -> void:
	var territory_ids: Dictionary[StringName, bool] = {}
	var puzzle_ids: Dictionary[String, bool] = {}
	for index: int in range(1, 7):
		var path: String = "res://data/territories/territory_%02d.tres" % index
		var territory: TerritoryData = load(path) as TerritoryData
		if territory == null:
			_fail("Territory '%s' failed to load as TerritoryData." % path)
			continue
		if territory_ids.has(territory.id):
			_fail("Duplicate territory id '%s'." % territory.id)
		territory_ids[territory.id] = true
		if territory.id != StringName("territory_%02d" % index):
			_fail("Territory '%s' has an unexpected id." % path)
		for entry: TerritoryPuzzleEntry in territory.puzzle_ids:
			if entry == null or entry.puzzle_id.is_empty():
				_fail("Territory '%s' contains an invalid puzzle entry." % territory.id)
				continue
			if puzzle_ids.has(entry.puzzle_id):
				_fail("Puzzle '%s' appears in more than one territory." % entry.puzzle_id)
			puzzle_ids[entry.puzzle_id] = true
			var level: Resource = load(entry.level_resource_path)
			if level == null:
				_fail("Puzzle '%s' resource '%s' failed to load." % [entry.puzzle_id, entry.level_resource_path])
			elif str(level.get("id")) != entry.puzzle_id:
				_fail("Puzzle id mismatch for '%s'." % entry.level_resource_path)
	var expected_count: int = 24
	if puzzle_ids.size() != expected_count:
		_fail("Expected %d unique puzzle entries; found %d." % [expected_count, puzzle_ids.size()])


func _fail(message: String) -> void:
	_errors += 1
	push_error("Smoke test: " + message)
