## Entry point for starting or continuing the game.
extends Control

const SETTINGS_SCENE: PackedScene = preload("res://ui/settings/settings_menu.tscn")

var _continue_button: GameButton
var _dialog: ConfirmDialog


func _ready() -> void:
	_apply_theme()
	var catalog: AssetCatalog = load("res://data/asset_catalog.tres") as AssetCatalog

	# Main background wallpaper (fundo-jogo.png)
	var background: TextureRect = TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if catalog != null:
		background.texture = catalog.menu_background if catalog.menu_background != null else catalog.placeholder_menu_background
	if background.texture == null:
		background.modulate = Color(0.12, 0.1, 0.18)
	add_child(background)

	var safe: SafeAreaContainer = SafeAreaContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.add_child(center)

	var panel: GamePanel = GamePanel.new()
	panel.custom_minimum_size = Vector2(540.0, 700.0)
	center.add_child(panel)

	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	panel.add_child(stack)

	# Main cover art / title image (capa - jogo.png)
	var logo: TextureRect = TextureRect.new()
	logo.custom_minimum_size = Vector2(0.0, 180.0)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if catalog != null:
		logo.texture = catalog.cover_art if catalog.cover_art != null else catalog.placeholder_game_logo
	logo.visible = logo.texture != null
	stack.add_child(logo)

	var title: LocalizedLabel = LocalizedLabel.new()
	title.translation_key = "ui.menu.title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	if logo.visible:
		# Hide text title if graphic cover art logo is visible to avoid duplication
		title.visible = false
	stack.add_child(title)

	var language: LanguageToggle = LanguageToggle.new()
	stack.add_child(language)

	if catalog != null and catalog.music_menu != null:
		AudioManager.play_music(catalog.music_menu)

	_continue_button = GameButton.new()
	_continue_button.set_localized("ui.menu.continue")
	_continue_button.pressed.connect(_on_continue)
	stack.add_child(_continue_button)

	var new_game: GameButton = GameButton.new()
	new_game.set_localized("ui.menu.new_game")
	new_game.pressed.connect(_on_new_game)
	stack.add_child(new_game)

	var settings: GameButton = GameButton.new()
	settings.set_localized("ui.menu.settings")
	settings.pressed.connect(_open_settings)
	stack.add_child(settings)

	if OS.has_feature("pc") or OS.has_feature("desktop"):
		var quit: GameButton = GameButton.new()
		quit.set_localized("ui.menu.quit")
		quit.pressed.connect(func() -> void: get_tree().quit())
		stack.add_child(quit)

	_dialog = ConfirmDialog.new()
	add_child(_dialog)
	EventBus.progress_changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if EventBus.progress_changed.is_connected(_refresh):
		EventBus.progress_changed.disconnect(_refresh)


func _on_continue() -> void:
	if GameManager.has_chosen_faction():
		SceneManager.change_scene("res://ui/world_map/world_map.tscn")
	else:
		SceneManager.change_scene("res://ui/faction_select/faction_select.tscn")


func _on_new_game() -> void:
	_dialog.ask("ui.dialog.new_game_title", "ui.dialog.new_game_message", "ui.dialog.confirm", "ui.dialog.cancel")
	_dialog.confirmed.connect(_confirm_new_game, CONNECT_ONE_SHOT)


func _confirm_new_game() -> void:
	GameManager.new_game()
	SceneManager.clear_history()
	SceneManager.change_scene("res://ui/faction_select/faction_select.tscn")


func _open_settings() -> void:
	var settings: Control = SETTINGS_SCENE.instantiate() as Control
	add_child(settings)


func _refresh() -> void:
	if is_instance_valid(_continue_button):
		_continue_button.visible = GameManager.has_save()


func _apply_theme() -> void:
	var game_theme: GameTheme = load("res://ui/common/game_theme.tres") as GameTheme
	if game_theme != null:
		theme = game_theme.build_theme()
