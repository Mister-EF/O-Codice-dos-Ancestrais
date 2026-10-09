## Faction Select screen controller.
class_name FactionSelectScreen
extends Control

@onready var _card_pirates: Button = $SafeArea/VBox/CardsScroll/CardsContainer/CardPirates
@onready var _card_scholars: Button = $SafeArea/VBox/CardsScroll/CardsContainer/CardScholars
@onready var _card_mercenaries: Button = $SafeArea/VBox/CardsScroll/CardsContainer/CardMercenaries

@onready var _lbl_name: LocalizedLabel = $SafeArea/VBox/Details/FactionName
@onready var _lbl_desc: LocalizedLabel = $SafeArea/VBox/Details/FactionDesc
@onready var _lbl_bonus: LocalizedLabel = $SafeArea/VBox/Details/FactionBonus
@onready var _btn_confirm: LocalizedButton = $SafeArea/VBox/Footer/BtnConfirm

var _selected_faction: GameManager.Faction = GameManager.Faction.PIRATES

func _ready() -> void:
	_card_pirates.pressed.connect(func() -> void: _select(GameManager.Faction.PIRATES))
	_card_scholars.pressed.connect(func() -> void: _select(GameManager.Faction.SCHOLARS))
	_card_mercenaries.pressed.connect(func() -> void: _select(GameManager.Faction.MERCENARIES))
	_btn_confirm.pressed.connect(_on_confirm_pressed)
	
	if GameManager.has_chosen_faction():
		_selected_faction = GameManager.get_faction()
	_update_view()
	_play_faction_music()

func _select(faction: GameManager.Faction) -> void:
	Haptics.vibrate()
	_selected_faction = faction
	_update_view()
	_play_faction_music()

func _play_faction_music() -> void:
	var fdata: FactionData = GameManager.get_faction_data_for(_selected_faction)
	if fdata != null and fdata.placeholder_music != null:
		AudioManager.play_music(fdata.placeholder_music)

func _update_view() -> void:
	_card_pirates.modulate = Color(1.2, 1.2, 0.8) if _selected_faction == GameManager.Faction.PIRATES else Color(0.7, 0.7, 0.7)
	_card_scholars.modulate = Color(1.2, 1.2, 0.8) if _selected_faction == GameManager.Faction.SCHOLARS else Color(0.7, 0.7, 0.7)
	_card_mercenaries.modulate = Color(1.2, 1.2, 0.8) if _selected_faction == GameManager.Faction.MERCENARIES else Color(0.7, 0.7, 0.7)
	
	var fdata: FactionData = GameManager.get_faction_data_for(_selected_faction)
	if fdata != null:
		_lbl_name.set_localized(fdata.name_key)
		_lbl_desc.set_localized(fdata.description_key)
		_lbl_bonus.set_localized(fdata.bonus_key, {"count": fdata.extra_flip_allowance, "percent": fdata.hint_discount, "seconds": fdata.time_bonus_seconds})

func _on_confirm_pressed() -> void:
	GameManager.select_faction(_selected_faction)
	SceneManager.clear_history()
	SceneManager.change_scene("res://ui/world_map/world_map.tscn")
