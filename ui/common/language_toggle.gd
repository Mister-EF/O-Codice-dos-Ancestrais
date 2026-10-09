## Small reusable language toggle button.
class_name LanguageToggle
extends Button

func _ready() -> void:
	custom_minimum_size = Vector2(140, 48)
	pressed.connect(_on_pressed)
	if EventBus != null:
		EventBus.language_changed.connect(_on_language_changed)
	_update_text()

func _on_pressed() -> void:
	Haptics.vibrate()
	var current: String = Localization.get_language()
	var langs: Array[String] = Localization.get_supported_languages()
	var idx: int = langs.find(current)
	var next_idx: int = (idx + 1) % langs.size()
	Localization.set_language(langs[next_idx])

func _on_language_changed(_loc: String) -> void:
	_update_text()

func _update_text() -> void:
	var cur: String = Localization.get_language()
	text = "🌐 " + Localization.get_language_display_name(cur)
