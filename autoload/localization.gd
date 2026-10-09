## Localization — Manages runtime language switching with JSON translation sources.
## Registers Godot Translation objects so tr() and Control auto_translate work.
## Provides placeholder substitution and fallback logic. Registered as autoload.
extends Node


## Supported locales. Order matters for display in settings UI.
const SUPPORTED_LOCALES: Array[String] = ["en", "pt_BR"]

## Default locale used as fallback and for first launch if device locale is unknown.
const DEFAULT_LOCALE: String = "en"

## Human-readable names in each language's OWN language.
const _LOCALE_DISPLAY_NAMES: Dictionary = {
	"en": "English",
	"pt_BR": "Português (Brasil)",
}

## In-memory dictionaries per locale: { "en": { "key": "value", ... }, ... }
var _dictionaries: Dictionary = {}

## Currently active locale.
var _current_locale: String = DEFAULT_LOCALE


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_all_translations()
	# Determine initial locale — saved choice takes priority.
	var saved_locale: String = _get_saved_locale()
	if saved_locale != "" and saved_locale in SUPPORTED_LOCALES:
		_apply_locale(saved_locale)
	else:
		var device_locale: String = OS.get_locale()
		var mapped: String = _map_device_locale(device_locale)
		_apply_locale(mapped)


# ── Public API ───────────────────────────────────────────────────────────────

## Change the active language. Validates, persists, and notifies the system.
func set_language(locale: String) -> void:
	if locale not in SUPPORTED_LOCALES:
		push_error("Localization: unsupported locale '%s'. Supported: %s" % [locale, str(SUPPORTED_LOCALES)])
		return
	if locale == _current_locale:
		return
	_apply_locale(locale)
	# Persist the choice through SaveSystem (may not be ready on first frame).
	if has_node("/root/SaveSystem"):
		SaveSystem.set_value("locale", locale)
	EventBus.language_changed.emit(locale)


## Returns the currently active locale string.
func get_language() -> String:
	return _current_locale


## Returns the list of supported locale codes.
func get_supported_languages() -> Array[String]:
	return SUPPORTED_LOCALES.duplicate()


## Returns the display name of a locale in its OWN language.
func get_language_display_name(locale: String) -> String:
	if locale in _LOCALE_DISPLAY_NAMES:
		return _LOCALE_DISPLAY_NAMES[locale]
	return locale


## Translates a key with optional {placeholder} substitution.
## Fallback chain: current locale → "en" → raw key (with warning).
func translate(key: String, params: Dictionary = {}) -> String:
	var text: String = _resolve_key(key)
	if params.size() > 0:
		text = _substitute_params(text, params)
	return text


## Returns true if the key exists in at least the current locale.
func has_key(key: String) -> bool:
	if _current_locale in _dictionaries:
		var dict: Dictionary = _dictionaries[_current_locale]
		return dict.has(key)
	return false


# ── Internal helpers ─────────────────────────────────────────────────────────

func _load_all_translations() -> void:
	for locale: String in SUPPORTED_LOCALES:
		var path: String = "res://localization/%s.json" % locale
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Localization: cannot open '%s': %s" % [path, error_string(FileAccess.get_open_error())])
			_dictionaries[locale] = {}
			continue
		var json_text: String = file.get_as_text()
		file.close()

		var json: JSON = JSON.new()
		var err: Error = json.parse(json_text)
		if err != OK:
			push_error("Localization: parse error in '%s' at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
			_dictionaries[locale] = {}
			continue

		var data: Variant = json.data
		if data is Dictionary:
			_dictionaries[locale] = data
		else:
			push_error("Localization: '%s' root is not a Dictionary." % path)
			_dictionaries[locale] = {}

		# Register a Godot Translation so tr() and auto_translate work.
		_register_translation(locale, data as Dictionary)


func _register_translation(locale: String, dict: Dictionary) -> void:
	var translation: Translation = Translation.new()
	translation.locale = locale
	for key: Variant in dict.keys():
		var k: String = key as String
		translation.add_message(StringName(k), dict[k] as String)
	TranslationServer.add_translation(translation)


func _apply_locale(locale: String) -> void:
	_current_locale = locale
	TranslationServer.set_locale(locale)


func _resolve_key(key: String) -> String:
	# Try current locale.
	if _current_locale in _dictionaries:
		var dict: Dictionary = _dictionaries[_current_locale]
		if dict.has(key):
			return dict[key] as String
	# Fallback to English.
	if _current_locale != DEFAULT_LOCALE and DEFAULT_LOCALE in _dictionaries:
		var en_dict: Dictionary = _dictionaries[DEFAULT_LOCALE]
		if en_dict.has(key):
			push_warning("Localization: key '%s' missing in '%s', falling back to '%s'." % [key, _current_locale, DEFAULT_LOCALE])
			return en_dict[key] as String
	# Key not found anywhere.
	push_warning("Localization: key '%s' not found in any locale." % key)
	return key


func _substitute_params(text: String, params: Dictionary) -> String:
	var result: String = text
	for param_key: Variant in params.keys():
		var pk: String = param_key as String
		var placeholder: String = "{%s}" % pk
		result = result.replace(placeholder, str(params[pk]))
	return result


func _map_device_locale(device_locale: String) -> String:
	var lower: String = device_locale.to_lower()
	if lower.begins_with("pt"):
		return "pt_BR"
	return DEFAULT_LOCALE


func _get_saved_locale() -> String:
	# On startup SaveSystem may not be ready yet; read raw file.
	var path: String = "user://codex_save.json"
	if not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var json_text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(json_text) != OK:
		return ""
	var data: Variant = json.data
	if data is Dictionary:
		var dict: Dictionary = data as Dictionary
		if dict.has("locale"):
			return dict["locale"] as String
	return ""
