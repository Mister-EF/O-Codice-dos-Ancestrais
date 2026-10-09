## Faction selection screen, also used to change faction without clearing progress.
extends Control

const SETTINGS_SCENE: PackedScene = preload("res://ui/settings/settings_menu.tscn")
const FACTIONS: Array[GameManager.Faction] = [
	GameManager.Faction.PIRATES,
	GameManager.Faction.SCHOLARS,
	GameManager.Faction.MERCENARIES,
]

var _selected: GameManager.Faction = GameManager.Faction.NONE
var _cards: Dictionary[int, Button] = {}
var _confirm: GameButton
var _dialog: ConfirmDialog
var _change_mode: bool = false
var _return_to: String = "res://ui/world_map/world_map.tscn"


func _ready() -> void:
	var params: Dictionary = SceneManager.current_params
	_change_mode = bool(params.get("changing_faction", false))
	_return_to = str(params.get("return_to", _return_to))
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.045, 0.055, 0.10)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var safe: SafeAreaContainer = SafeAreaContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	var margins: MarginContainer = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 18)
	margins.add_theme_constant_override("margin_right", 18)
	margins.add_theme_constant_override("margin_top", 24)
	margins.add_theme_constant_override("margin_bottom", 24)
	safe.add_child(margins)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margins.add_child(layout)
	var heading: LocalizedLabel = LocalizedLabel.new()
	heading.translation_key = "ui.faction.title"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	layout.add_child(heading)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	layout.add_child(row)
	for faction: GameManager.Faction in FACTIONS:
		var data: FactionData = GameManager.get_faction_data_for(faction)
		if data == null:
			push_error("FactionSelect: missing FactionData for faction %d." % faction)
			continue
		var card: GameButton = GameButton.new()
		card.custom_minimum_size = Vector2(0.0, 360.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.pressed.connect(_select_faction.bind(faction))
		row.add_child(card)
		_cards[faction] = card
		var content: VBoxContainer = VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.add_child(content)
		var portrait: TextureRect = TextureRect.new()
		portrait.custom_minimum_size = Vector2(0.0, 110.0)
		var catalog: AssetCatalog = load("res://data/asset_catalog.tres") as AssetCatalog
		portrait.texture = data.placeholder_icon
		if portrait.texture == null and catalog != null:
			portrait.texture = catalog.faction_icon_fallback
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.modulate = data.theme_color
		content.add_child(portrait)
		if portrait.texture == null:
			var placeholder: LocalizedLabel = LocalizedLabel.new()
			placeholder.set_localized("ui.faction.portrait_placeholder")
			placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content.add_child(placeholder)
		var name_label: LocalizedLabel = LocalizedLabel.new()
		name_label.set_localized(data.name_key)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(name_label)
		var lore: LocalizedLabel = LocalizedLabel.new()
		lore.set_localized(data.description_key)
		lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lore.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(lore)
		var bonus: LocalizedLabel = LocalizedLabel.new()
		bonus.set_localized(data.bonus_key)
		bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(bonus)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	layout.add_child(actions)
	var settings: GameButton = GameButton.new()
	settings.set_localized("ui.menu.settings")
	settings.pressed.connect(_open_settings)
	actions.add_child(settings)
	var back: GameButton = GameButton.new()
	back.set_localized("ui.common.back")
	back.pressed.connect(func() -> void: SceneManager.go_back())
	actions.add_child(back)
	_confirm = GameButton.new()
	_confirm.set_localized("ui.faction.confirm")
	_confirm.disabled = true
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
		if _cards.has(faction):
			var button: Button = _cards[faction]
			button.modulate = Color(1.0, 0.82, 0.39) if faction == _selected else Color.WHITE
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
