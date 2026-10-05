## Boot scene — Temporary infrastructure test.
## Displays localized debug text and buttons to verify the foundation works.
## Will be replaced in Step 5 by the SceneManager/MainMenu flow.
extends Control


## References to labels that display debug state.
var _title_label: LocalizedLabel
var _subtitle_label: LocalizedLabel
var _language_label: LocalizedLabel
var _faction_label: LocalizedLabel
var _save_label: LocalizedLabel
var _switch_lang_btn: LocalizedButton
var _cycle_faction_btn: LocalizedButton

## Faction cycle order for the test button.
const _FACTION_ORDER: Array[GameManager.Faction] = [
	GameManager.Faction.NONE,
	GameManager.Faction.PIRATES,
	GameManager.Faction.SCHOLARS,
	GameManager.Faction.MERCENARIES,
]


func _ready() -> void:
	_build_ui()
	_connect_signals()
	_refresh_all()


func _build_ui() -> void:
	# Root background.
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.12, 0.1, 0.18, 1.0)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	# Safe area wrapper.
	var safe: SafeAreaContainer = SafeAreaContainer.new()
	safe.set_anchors_preset(PRESET_FULL_RECT)
	add_child(safe)

	# Main VBox.
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 24)
	safe.add_child(vbox)

	# Spacer top.
	var spacer_top: Control = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(spacer_top)

	# Title.
	_title_label = LocalizedLabel.new()
	_title_label.translation_key = "boot.title"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	vbox.add_child(_title_label)

	# Subtitle.
	_subtitle_label = LocalizedLabel.new()
	_subtitle_label.translation_key = "boot.subtitle"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 18)
	_subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(_subtitle_label)

	# Separator.
	var sep1: HSeparator = HSeparator.new()
	vbox.add_child(sep1)

	# Language info.
	_language_label = LocalizedLabel.new()
	_language_label.translation_key = "boot.language_label"
	_language_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_language_label.add_theme_font_size_override("font_size", 22)
	_language_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_language_label)

	# Faction info.
	_faction_label = LocalizedLabel.new()
	_faction_label.translation_key = "boot.faction_label"
	_faction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_faction_label.add_theme_font_size_override("font_size", 22)
	_faction_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_faction_label)

	# Save status info.
	_save_label = LocalizedLabel.new()
	_save_label.translation_key = "boot.save_status"
	_save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_label.add_theme_font_size_override("font_size", 22)
	_save_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_save_label)

	# Separator.
	var sep2: HSeparator = HSeparator.new()
	vbox.add_child(sep2)

	# Button container (centered).
	var btn_box: VBoxContainer = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 16)
	btn_box.size_flags_horizontal = SIZE_SHRINK_CENTER
	vbox.add_child(btn_box)

	# Switch Language button.
	_switch_lang_btn = LocalizedButton.new()
	_switch_lang_btn.translation_key = "ui.switch_language"
	_switch_lang_btn.custom_minimum_size = Vector2(320, 88)
	_switch_lang_btn.pressed.connect(_on_switch_language_pressed)
	btn_box.add_child(_switch_lang_btn)

	# Cycle Faction button.
	_cycle_faction_btn = LocalizedButton.new()
	_cycle_faction_btn.translation_key = "ui.cycle_faction"
	_cycle_faction_btn.custom_minimum_size = Vector2(320, 88)
	_cycle_faction_btn.pressed.connect(_on_cycle_faction_pressed)
	btn_box.add_child(_cycle_faction_btn)


func _connect_signals() -> void:
	EventBus.language_changed.connect(_on_language_changed)
	EventBus.faction_selected.connect(_on_faction_selected)
	EventBus.save_completed.connect(_on_save_completed)


func _on_language_changed(_locale: String) -> void:
	_refresh_all()


func _on_faction_selected(_faction_id: StringName) -> void:
	_refresh_all()


func _on_save_completed(_success: bool) -> void:
	_refresh_save_label()


func _on_switch_language_pressed() -> void:
	Haptics.vibrate()
	var current: String = Localization.get_language()
	var languages: Array[String] = Localization.get_supported_languages()
	var idx: int = languages.find(current)
	var next_idx: int = (idx + 1) % languages.size()
	Localization.set_language(languages[next_idx])
	# Tween feedback.
	_tween_press(_switch_lang_btn)


func _on_cycle_faction_pressed() -> void:
	Haptics.vibrate()
	var current: GameManager.Faction = GameManager.get_faction()
	var idx: int = _FACTION_ORDER.find(current)
	var next_idx: int = (idx + 1) % _FACTION_ORDER.size()
	GameManager.select_faction(_FACTION_ORDER[next_idx])
	# Tween feedback.
	_tween_press(_cycle_faction_btn)


func _refresh_all() -> void:
	_refresh_language_label()
	_refresh_faction_label()
	_refresh_save_label()


func _refresh_language_label() -> void:
	var lang_name: String = Localization.get_language_display_name(Localization.get_language())
	_language_label.set_localized("boot.language_label", {"language": lang_name})


func _refresh_faction_label() -> void:
	var faction_name: String
	if GameManager.has_chosen_faction():
		var fd: FactionData = GameManager.get_faction_data()
		if fd != null:
			faction_name = Localization.translate(fd.name_key)
		else:
			faction_name = str(GameManager.get_faction())
	else:
		faction_name = Localization.translate("ui.no_faction")
	_faction_label.set_localized("boot.faction_label", {"faction": faction_name})


func _refresh_save_label() -> void:
	var status_key: String = "boot.save_exists" if SaveSystem.exists() else "boot.no_save"
	var status_text: String = Localization.translate(status_key)
	_save_label.set_localized("boot.save_status", {"status": status_text})


func _tween_press(node: Control) -> void:
	node.pivot_offset = node.size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(node, "scale", Vector2(0.92, 0.92), 0.06)
	tween.tween_property(node, "scale", Vector2.ONE, 0.1)
