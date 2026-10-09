## Faction selection screen, updated with mobile-friendly vertical cards,
## clean button padding, and fundo-jogo.png background wallpaper.
extends Control

const SETTINGS_SCENE: PackedScene = preload("res://ui/settings/settings_menu.tscn")
const FACTIONS: Array[GameManager.Faction] = [
	GameManager.Faction.PIRATES,
	GameManager.Faction.SCHOLARS,
	GameManager.Faction.MERCENARIES,
]

var _selected: GameManager.Faction = GameManager.Faction.NONE
var _card_panels: Dictionary[int, GamePanel] = {}
var _card_select_btns: Dictionary[int, GameButton] = {}
var _confirm: GameButton
var _dialog: ConfirmDialog
var _change_mode: bool = false
var _return_to: String = "res://ui/world_map/world_map.tscn"


func _ready() -> void:
	var params: Dictionary = SceneManager.current_params
	_change_mode = bool(params.get("changing_faction", false))
	_return_to = str(params.get("return_to", _return_to))

	var catalog: AssetCatalog = load("res://data/asset_catalog.tres") as AssetCatalog

	# Main Wallpaper Background (fundo-jogo.png)
	var background: TextureRect = TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if catalog != null and catalog.menu_background != null:
		background.texture = catalog.menu_background
	else:
		background.self_modulate = Color(0.1, 0.12, 0.2)
	add_child(background)

	var safe: SafeAreaContainer = SafeAreaContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe)

	var margins: MarginContainer = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 20)
	margins.add_theme_constant_override("margin_right", 20)
	margins.add_theme_constant_override("margin_top", 20)
	margins.add_theme_constant_override("margin_bottom", 20)
	safe.add_child(margins)

	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margins.add_child(layout)

	# Screen Title
	var heading: LocalizedLabel = LocalizedLabel.new()
	heading.translation_key = "ui.faction.title"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color(0.96, 0.88, 0.55))
	layout.add_child(heading)

	# Scroll Container for vertical mobile cards
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	var cards_vbox: VBoxContainer = VBoxContainer.new()
	cards_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(cards_vbox)

	for faction: GameManager.Faction in FACTIONS:
		var data: FactionData = GameManager.get_faction_data_for(faction)
		if data == null:
			push_error("FactionSelect: missing FactionData for faction %d." % faction)
			continue

		var panel: GamePanel = GamePanel.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards_vbox.add_child(panel)
		_card_panels[faction] = panel

		var card_box: VBoxContainer = VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 10)
		panel.add_child(card_box)

		# Header row with Portrait Icon & Name
		var header_row: HBoxContainer = HBoxContainer.new()
		header_row.add_theme_constant_override("separation", 14)
		card_box.add_child(header_row)

		var portrait: TextureRect = TextureRect.new()
		portrait.custom_minimum_size = Vector2(72.0, 72.0)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = data.placeholder_icon
		if portrait.texture == null and catalog != null:
			portrait.texture = catalog.faction_icon_fallback
		portrait.modulate = data.theme_color
		header_row.add_child(portrait)

		var name_label: LocalizedLabel = LocalizedLabel.new()
		name_label.set_localized(data.name_key)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.65))
		header_row.add_child(name_label)

		# Lore Description
		var lore: LocalizedLabel = LocalizedLabel.new()
		lore.set_localized(data.description_key)
		lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lore.add_theme_font_size_override("font_size", 14)
		lore.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
		card_box.add_child(lore)

		# Gameplay Bonus
		var bonus: LocalizedLabel = LocalizedLabel.new()
		bonus.set_localized(data.bonus_key)
		bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bonus.add_theme_font_size_override("font_size", 14)
		bonus.add_theme_color_override("font_color", Color(0.45, 0.88, 0.65))
		card_box.add_child(bonus)

		# Select button inside the card
		var select_btn: GameButton = GameButton.new()
		select_btn.translation_key = "ui.select_faction"
		select_btn.custom_minimum_size = Vector2(0.0, 64.0)
		select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select_btn.pressed.connect(_select_faction.bind(faction))
		card_box.add_child(select_btn)
		_card_select_btns[faction] = select_btn

	# Action Bar at bottom
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	layout.add_child(actions)

	var back: GameButton = GameButton.new()
	back.set_localized("ui.common.back")
	back.custom_minimum_size = Vector2(120.0, 64.0)
	back.pressed.connect(func() -> void: SceneManager.go_back())
	actions.add_child(back)

	var settings: GameButton = GameButton.new()
	settings.set_localized("ui.menu.settings")
	settings.custom_minimum_size = Vector2(120.0, 64.0)
	settings.pressed.connect(_open_settings)
	actions.add_child(settings)

	_confirm = GameButton.new()
	_confirm.set_localized("ui.faction.confirm")
	_confirm.disabled = true
	_confirm.custom_minimum_size = Vector2(0.0, 64.0)
	_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm.pressed.connect(_confirm_selection)
	actions.add_child(_confirm)

	_dialog = ConfirmDialog.new()
	add_child(_dialog)
	_selected = GameManager.get_faction() if _change_mode else GameManager.Faction.NONE
	_update_selection()


func _select_faction(faction: GameManager.Faction) -> void:
	_selected = faction
	_update_selection()


func _update_selection() -> void:
	for faction: GameManager.Faction in FACTIONS:
		if _card_panels.has(faction):
			var is_sel: bool = (faction == _selected)
			var panel: GamePanel = _card_panels[faction]
			panel.modulate = Color(1.1, 1.05, 0.8) if is_sel else Color(0.9, 0.9, 0.9)
			if _card_select_btns.has(faction):
				var btn: GameButton = _card_select_btns[faction]
				btn.modulate = Color(1.0, 0.85, 0.4) if is_sel else Color.WHITE
	_confirm.disabled = _selected == GameManager.Faction.NONE


func _confirm_selection() -> void:
	if _selected == GameManager.Faction.NONE:
		return
	if _change_mode:
		_dialog.ask("ui.dialog.change_faction_title", "ui.dialog.change_faction_message", "ui.dialog.confirm", "ui.dialog.cancel")
		_dialog.confirmed.connect(_apply_selection, CONNECT_ONE_SHOT)
	else:
		_apply_selection()


func _apply_selection() -> void:
	GameManager.select_faction(_selected)
	SceneManager.replace_scene(_return_to)


func _open_settings() -> void:
	add_child(SETTINGS_SCENE.instantiate())
