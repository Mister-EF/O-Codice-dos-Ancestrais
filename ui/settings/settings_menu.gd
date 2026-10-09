## Modal settings overlay with live localization and persisted game settings.
extends Control

const FACTION_SCENE: String = "res://ui/faction_select/faction_select.tscn"

var _music: HSlider
var _sfx: HSlider
var _haptics: CheckButton
var _dialog: ConfirmDialog
var _haptics_label: LocalizedLabel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.045, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: GamePanel = GamePanel.new()
	panel.custom_minimum_size = Vector2(560.0, 940.0)
	center.add_child(panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 10)
	scroll.add_child(layout)
	var title: LocalizedLabel = LocalizedLabel.new()
	title.translation_key = "ui.settings.title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)
	var language_title: LocalizedLabel = LocalizedLabel.new()
	language_title.translation_key = "ui.settings.language"
	layout.add_child(language_title)
	layout.add_child(LanguageToggle.new())
	_music = _add_slider(layout, "ui.settings.music", GameManager.get_music_volume())
	_music.value_changed.connect(GameManager.set_music_volume)
	_sfx = _add_slider(layout, "ui.settings.sfx", GameManager.get_sfx_volume())
	_sfx.value_changed.connect(GameManager.set_sfx_volume)
	var haptics_row: HBoxContainer = HBoxContainer.new()
	layout.add_child(haptics_row)
	_haptics_label = LocalizedLabel.new()
	_haptics_label.translation_key = "ui.settings.haptics"
	_haptics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	haptics_row.add_child(_haptics_label)
	_haptics = CheckButton.new()
	_haptics.custom_minimum_size = Vector2(88.0, 56.0)
	_haptics.button_pressed = GameManager.is_haptics_enabled()
	_haptics.toggled.connect(GameManager.set_haptics_enabled)
	haptics_row.add_child(_haptics)
	var faction: GameButton = GameButton.new()
	faction.set_localized("ui.settings.change_faction")
	faction.pressed.connect(_change_faction)
	layout.add_child(faction)
	var reset: GameButton = GameButton.new()
	reset.set_localized("ui.settings.reset")
	reset.pressed.connect(_confirm_reset)
	layout.add_child(reset)
	var about: LocalizedLabel = LocalizedLabel.new()
	about.translation_key = "ui.settings.about"
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(about)
	var close: GameButton = GameButton.new()
	close.set_localized("ui.common.close")
	close.pressed.connect(queue_free)
	layout.add_child(close)
	_dialog = ConfirmDialog.new()
	add_child(_dialog)
	EventBus.language_changed.connect(_on_language_changed)
	SceneManager.push_back_handler(_close_settings)


func _exit_tree() -> void:
	if EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.disconnect(_on_language_changed)
	SceneManager.pop_back_handler(_close_settings)


func _add_slider(parent: VBoxContainer, title_key: String, initial_value: float) -> HSlider:
	var label: LocalizedLabel = LocalizedLabel.new()
	label.translation_key = title_key
	parent.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial_value
	slider.custom_minimum_size = Vector2(0.0, 56.0)
	parent.add_child(slider)
	return slider


func _change_faction() -> void:
	_open_faction_select()


func _open_faction_select() -> void:
	SceneManager.change_scene(FACTION_SCENE, {
		"changing_faction": true,
		"return_to": get_tree().current_scene.scene_file_path,
	})


func _confirm_reset() -> void:
	_dialog.ask("ui.dialog.reset_title", "ui.dialog.reset_message", "ui.dialog.confirm", "ui.dialog.cancel")
	_dialog.confirmed.connect(_reset_progress, CONNECT_ONE_SHOT)


func _reset_progress() -> void:
	GameManager.new_game()
	SceneManager.clear_history()
	SceneManager.replace_scene("res://ui/main_menu/main_menu.tscn")


func _on_language_changed(_locale: String) -> void:
	if is_instance_valid(_haptics_label):
		_haptics_label.set_localized("ui.settings.haptics")


func _close_settings() -> void:
	queue_free()
