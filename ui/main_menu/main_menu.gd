## Main Menu screen controller.
class_name MainMenuScreen
extends Control

@export var asset_catalog: AssetCatalog = preload("res://data/asset_catalog.tres")

@onready var _btn_continue: LocalizedButton = $SafeArea/VBox/MenuButtons/BtnContinue
@onready var _btn_new_game: LocalizedButton = $SafeArea/VBox/MenuButtons/BtnNewGame
@onready var _btn_settings: LocalizedButton = $SafeArea/VBox/MenuButtons/BtnSettings
@onready var _btn_quit: LocalizedButton = $SafeArea/VBox/MenuButtons/BtnQuit
@onready var _confirm_dialog: ConfirmDialog = $ConfirmDialog

func _ready() -> void:
	if asset_catalog != null and asset_catalog.music_menu != null:
		AudioManager.play_music(asset_catalog.music_menu)

	_btn_continue.pressed.connect(_on_continue_pressed)
	_btn_new_game.pressed.connect(_on_new_game_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)
	_confirm_dialog.confirmed.connect(_on_new_game_confirmed)
	
	_btn_continue.visible = GameManager.has_save()
	if OS.has_feature("web") or OS.has_feature("mobile"):
		_btn_quit.visible = false

func _on_continue_pressed() -> void:
	GameManager.continue_game()
	_navigate_after_login()

func _on_new_game_pressed() -> void:
	if GameManager.has_save():
		_confirm_dialog.popup_dialog("ui.new_game", "ui.new_game_confirm")
	else:
		_on_new_game_confirmed()

func _on_new_game_confirmed() -> void:
	GameManager.new_game()
	SceneManager.clear_history()
	SceneManager.change_scene("res://ui/faction_select/faction_select.tscn")

func _on_settings_pressed() -> void:
	SceneManager.change_scene("res://ui/settings/settings_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _navigate_after_login() -> void:
	SceneManager.clear_history()
	if not GameManager.has_chosen_faction():
		SceneManager.change_scene("res://ui/faction_select/faction_select.tscn")
	else:
		SceneManager.change_scene("res://ui/world_map/world_map.tscn")
