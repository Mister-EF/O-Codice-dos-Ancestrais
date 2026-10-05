## Localization Validator — Headless test script.
## Run with: godot --headless -s res://tests/localization_validator.gd
## Fails (exit code 1) when:
##   - A key exists in one language but not the other
##   - A translation value is empty
##   - {placeholders} differ between languages
##   - Hardcoded .text assignments found in .gd/.tscn files (warning only)
extends SceneTree


var _errors: int = 0
var _warnings: int = 0


func _init() -> void:
	_run_validation()
	if _errors > 0:
		print("\n❌ LOCALIZATION VALIDATION FAILED: %d error(s), %d warning(s)" % [_errors, _warnings])
		quit(1)
	else:
		print("\n✅ LOCALIZATION VALIDATION PASSED: 0 errors, %d warning(s)" % _warnings)
		quit(0)


func _run_validation() -> void:
	print("═══ Localization Validator ═══\n")

	var en: Dictionary = _load_json("res://localization/en.json")
	var pt: Dictionary = _load_json("res://localization/pt_BR.json")

	if en.is_empty() and pt.is_empty():
		_error("Both translation files are empty or failed to load.")
		return

	# 1. Check keys present in EN but missing in PT_BR.
	print("── Checking EN keys exist in PT_BR ──")
	for key: Variant in en.keys():
		var k: String = key as String
		if not pt.has(k):
			_error("Key '%s' exists in en.json but MISSING in pt_BR.json" % k)

	# 2. Check keys present in PT_BR but missing in EN.
	print("── Checking PT_BR keys exist in EN ──")
	for key: Variant in pt.keys():
		var k: String = key as String
		if not en.has(k):
			_error("Key '%s' exists in pt_BR.json but MISSING in en.json" % k)

	# 3. Check for empty values.
	print("── Checking for empty values ──")
	for key: Variant in en.keys():
		var k: String = key as String
		var val: String = en[k] as String
		if val.strip_edges() == "":
			_error("Key '%s' has EMPTY value in en.json" % k)

	for key: Variant in pt.keys():
		var k: String = key as String
		var val: String = pt[k] as String
		if val.strip_edges() == "":
			_error("Key '%s' has EMPTY value in pt_BR.json" % k)

	# 4. Check placeholders match.
	print("── Checking placeholder consistency ──")
	for key: Variant in en.keys():
		var k: String = key as String
		if not pt.has(k):
			continue
		var en_placeholders: Array[String] = _extract_placeholders(en[k] as String)
		var pt_placeholders: Array[String] = _extract_placeholders(pt[k] as String)
		en_placeholders.sort()
		pt_placeholders.sort()
		if en_placeholders != pt_placeholders:
			_error("Key '%s' has mismatched placeholders: EN=%s PT_BR=%s" % [k, str(en_placeholders), str(pt_placeholders)])

	# 5. Scan for hardcoded strings (warnings only).
	print("── Scanning for hardcoded visible strings ──")
	_scan_hardcoded_strings("res://")

	print("\n── Summary: %d error(s), %d warning(s) ──" % [_errors, _warnings])


func _load_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_error("Cannot open '%s': %s" % [path, error_string(FileAccess.get_open_error())])
		return {}
	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: Error = json.parse(json_text)
	if err != OK:
		_error("Parse error in '%s' at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}

	var data: Variant = json.data
	if data is Dictionary:
		return data as Dictionary
	_error("'%s' root is not a Dictionary." % path)
	return {}


func _extract_placeholders(text: String) -> Array[String]:
	var placeholders: Array[String] = []
	var regex: RegEx = RegEx.new()
	regex.compile("\\{(\\w+)\\}")
	var matches: Array[RegExMatch] = regex.search_all(text)
	for m: RegExMatch in matches:
		placeholders.append(m.get_string(1))
	return placeholders


func _scan_hardcoded_strings(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var full_path: String = dir_path.path_join(file_name)

		if dir.current_is_dir():
			# Skip hidden dirs, .godot, .git, tests, addons, localization.
			if not file_name.begins_with(".") and file_name != "tests" and file_name != "localization" and file_name != "addons":
				_scan_hardcoded_strings(full_path)
		elif file_name.ends_with(".gd") or file_name.ends_with(".tscn"):
			_check_file_for_hardcoded(full_path)

		file_name = dir.get_next()
	dir.list_dir_end()


func _check_file_for_hardcoded(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var content: String = file.get_as_text()
	file.close()

	var lines: PackedStringArray = content.split("\n")
	for i: int in range(lines.size()):
		var line: String = lines[i].strip_edges()

		# Skip comments.
		if line.begins_with("#") or line.begins_with("//"):
			continue

		# Check for .text = "..." assignments in GDScript (not translation keys).
		if ".text = \"" in line:
			# Exclude lines that use translate(), tr(), set_localized(), or translation_key.
			if "translate(" not in line and "tr(" not in line and "set_localized(" not in line and "translation_key" not in line:
				# Exclude obvious non-visible assignments like test setup or debug.
				if "push_error" not in line and "push_warning" not in line and "print(" not in line:
					_warn("Possible hardcoded string at %s:%d → %s" % [path, i + 1, line])

		# Check for text = "..." in .tscn files.
		if path.ends_with(".tscn") and line.begins_with("text = \""):
			var value: String = line.substr(8).trim_suffix("\"")
			# Allow empty strings and single-character values.
			if value.length() > 1:
				_warn("Possible hardcoded text in scene at %s:%d → %s" % [path, i + 1, line])


func _error(msg: String) -> void:
	_errors += 1
	print("  ❌ ERROR: %s" % msg)


func _warn(msg: String) -> void:
	_warnings += 1
	print("  ⚠️ WARN:  %s" % msg)
