## TestLocalizationValidator — Headless validator comparing en.json and pt_BR.json.
## Ensures 100% key parity and identical {placeholder} tokens across all supported languages.
class_name TestLocalizationValidator
extends RefCounted


var _errors: Array[String] = []


func run_validation() -> bool:
	_errors.clear()
	print("--- Running TestLocalizationValidator ---")

	var en_dict: Dictionary = _load_json("res://localization/en.json")
	var pt_dict: Dictionary = _load_json("res://localization/pt_BR.json")

	if en_dict.is_empty() or pt_dict.is_empty():
		_errors.append("Failed to load translation dictionaries.")
		return false

	# Check keys in en exist in pt_BR
	for key_var: Variant in en_dict.keys():
		var key: String = key_var as String
		if not pt_dict.has(key):
			_errors.append("Key missing in pt_BR: " + key)
		else:
			_check_placeholders(key, en_dict[key] as String, pt_dict[key] as String)

	# Check keys in pt_BR exist in en
	for key_var: Variant in pt_dict.keys():
		var key: String = key_var as String
		if not en_dict.has(key):
			_errors.append("Key missing in en: " + key)

	if _errors.is_empty():
		print("Localization validation PASSED: %d keys verified." % en_dict.size())
		return true
	else:
		for err: String in _errors:
			push_error(err)
		print("Localization validation FAILED with %d errors." % _errors.size())
		return false


func _load_json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return {}
	return json.data as Dictionary if json.data is Dictionary else {}


func _check_placeholders(key: String, text_a: String, text_b: String) -> void:
	var tokens_a: Array[String] = _extract_tokens(text_a)
	var tokens_b: Array[String] = _extract_tokens(text_b)
	tokens_a.sort()
	tokens_b.sort()
	if tokens_a != tokens_b:
		_errors.append("Placeholder mismatch in key '%s': %s vs %s" % [key, str(tokens_a), str(tokens_b)])


func _extract_tokens(text: String) -> Array[String]:
	var tokens: Array[String] = []
	var start: int = 0
	while true:
		var open_idx: int = text.find("{", start)
		if open_idx == -1:
			break
		var close_idx: int = text.find("}", open_idx)
		if close_idx == -1:
			break
		tokens.append(text.substr(open_idx, close_idx - open_idx + 1))
		start = close_idx + 1
	return tokens
