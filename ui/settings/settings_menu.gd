## Settings modal screen controller.
class_name SettingsMenu
extends Control

signal closed

@onready var _btn_en: Button = $SafeArea/VBox/Content/LanguageSection/HBox/BtnEn
@onready var _btn_pt: Button = $SafeArea/VBox/Content/LanguageSection/HBox/BtnPt
@onready var _music_slider: HSlider = $SafeArea/VBox/Content/AudioSection/MusicHBox/MusicSlider
@onready var _sfx_slider: HSlider = $SafeArea/VBox/Content/AudioSection/SfxHBox/SfxSlider
@onready var _haptics_check: CheckButton = $SafeArea/VBox/Content/HapticsSection/HapticsCheck
@onready var _btn_change_faction: LocalizedButton = $SafeArea/VBox/Content/ActionsSection/BtnChangeFaction
@onready var _btn_reset_progress: LocalizedButton = $SafeArea/VBox/Content/ActionsSection/BtnResetProgress
@onready var _btn_back: LocalizedButton = $SafeArea/VBox/Footer/BtnBack
@onready var _confirm_dialog: ConfirmDialog = $ConfirmDialog

var _pending_action: String = ""

func _ready() -> void:
	_setup_controls()
	_refresh_ui()
	if EventBus != null:
		EventBus.language_changed.connect(func(_loc: String) -> void: _refresh_ui())

func _setup_controls() -> void:
	_btn_en.pressed.connect(func() -> void: Localization.set_language("en"))
	_btn_pt.pressed.connect(func() -> void: Localization.set_language("pt_BR"))
	
	_music_slider.value_changed.connect(func(val: float) -> void: GameManager.set_music_volume(val / 100.0))
	_sfx_slider.value_changed.connect(func(val: float) -> void: GameManager.set_sfx_volume(val / 100.0))
	_haptics_check.toggled.connect(func(enabled: bool) -> void: GameManager.set_haptics_enabled(enabled))
	
	_btn_change_faction.pressed.connect(_on_change_faction_pressed)
	_btn_reset_progress.pressed.connect(_on_reset_progress_pressed)
	_btn_back.pressed.connect(_on_back_pressed)
	
	_confirm_dialog.confirmed.connect(_on_dialog_confirmed)

func _refresh_ui() -> void:
	var cur_lang: String = Localization.get_language()
	_btn_en.modulate = Color(0.2, 0.9, 0.6) if cur_lang == "en" else Color(0.7, 0.7, 0.7)
	_btn_pt.modulate = Color(0.2, 0.9, 0.6) if cur_lang == "pt_BR" else Color(0.7, 0.7, 0.7)
	
	_music_slider.value = GameManager.get_music_volume() * 100.0
	_sfx_slider.value = GameManager.get_sfx_volume() * 100.0
	_haptics_check.button_pressed = GameManager.is_haptics_enabled()

func _on_change_faction_pressed() -> void:
	_pending_action = "change_faction"
	_confirm_dialog.popup_dialog("ui.settings.change_faction_title", "ui.settings.change_faction_msg")

func _on_reset_progress_pressed() -> void:
	_pending_action = "reset_progress"
	_confirm_dialog.popup_dialog("ui.settings.reset_title", "ui.settings.reset_msg")

func _on_dialog_confirmed() -> void:
	if _pending_action == "change_faction":
		SceneManager.change_scene("res://ui/faction_select/faction_select.tscn")
	elif _pending_action == "reset_progress":
		GameManager.new_game()
		SceneManager.clear_history()
		SceneManager.change_scene("res://ui/main_menu/main_menu.tscn")

func _on_back_pressed() -> void:
	closed.emit()
	if not SceneManager.go_back():
		SceneManager.change_scene("res://ui/main_menu/main_menu.tscn")
