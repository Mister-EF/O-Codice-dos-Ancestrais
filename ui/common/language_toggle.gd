## Two-button locale selector whose labels retain their native language.
class_name LanguageToggle
extends HBoxContainer

var _english: GameButton
var _portuguese: GameButton


func _ready() -> void:
	_english = GameButton.new()
	_english.set_localized("ui.language.english_name")
	_english.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_english.pressed.connect(func() -> void: Localization.set_language("en"))
	add_child(_english)
	_portuguese = GameButton.new()
	_portuguese.set_localized("ui.language.portuguese_name")
	_portuguese.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_portuguese.pressed.connect(func() -> void: Localization.set_language("pt_BR"))
	add_child(_portuguese)
	EventBus.language_changed.connect(_refresh_selected)
	_refresh_selected(Localization.get_language())


func _exit_tree() -> void:
	if EventBus.language_changed.is_connected(_refresh_selected):
		EventBus.language_changed.disconnect(_refresh_selected)


func _refresh_selected(_locale: String) -> void:
	if not is_instance_valid(_english) or not is_instance_valid(_portuguese):
		return
	_english.set_localized("ui.language.english_name")
	_portuguese.set_localized("ui.language.portuguese_name")
	_english.modulate = Color(1.0, 0.83, 0.38) if Localization.get_language() == "en" else Color.WHITE
	_portuguese.modulate = Color(1.0, 0.83, 0.38) if Localization.get_language() == "pt_BR" else Color.WHITE
