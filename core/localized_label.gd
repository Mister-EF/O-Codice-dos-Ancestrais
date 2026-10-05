## LocalizedLabel — A Label that automatically updates its text
## from a translation key, refreshing on language_changed.
class_name LocalizedLabel
extends Label


## Translation key to resolve via Localization.translate().
@export var translation_key: String = ""

## Optional parameters for {placeholder} substitution.
@export var params: Dictionary = {}


func _ready() -> void:
	EventBus.language_changed.connect(_on_language_changed)
	_refresh()


func _exit_tree() -> void:
	if EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.disconnect(_on_language_changed)


## Set the translation key and optional params from code, then refresh.
func set_localized(key: String, p: Dictionary = {}) -> void:
	translation_key = key
	params = p
	_refresh()


func _on_language_changed(_locale: String) -> void:
	_refresh()


func _refresh() -> void:
	if translation_key == "":
		return
	# Disable Godot's built-in auto_translate so we manage it ourselves.
	auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	text = Localization.translate(translation_key, params)
