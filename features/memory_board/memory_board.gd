## Main UI view controller for the Memory Board puzzle feature.
class_name MemoryBoard
extends Control

signal level_finished(result: PuzzleResult)
signal exit_requested()

@export var card_scene: PackedScene = preload("res://features/memory_board/memory_card.tscn")
@export var placeholder_card_back: Texture2D = null
@export var placeholder_card_front: Texture2D = null

var _level: MemoryBoardLevel = null
var _logic: MemoryBoardLogic = MemoryBoardLogic.new()
var _cards: Array[MemoryCard] = []
var _time_spent: float = 0.0
var _timer_active: bool = false
var _hints_used: int = 0
var _is_resolving: bool = false

@onready var _title_label: LocalizedLabel = $SafeArea/VBox/Header/TitleLabel
@onready var _moves_label: LocalizedLabel = $SafeArea/VBox/Header/MovesLabel
@onready var _timer_label: LocalizedLabel = $SafeArea/VBox/Header/TimerLabel
@onready var _grid_container: GridContainer = $SafeArea/VBox/GridCenter/GridContainer
@onready var _hint_button: LocalizedButton = $SafeArea/VBox/Footer/HintButton
@onready var _back_button: LocalizedButton = $SafeArea/VBox/Footer/BackButton
@onready var _popup_panel: Panel = $PopupPanel
@onready var _popup_label: Label = $PopupPanel/VBox/PopupLabel
@onready var _popup_close_button: Button = $PopupPanel/VBox/CloseButton

# End panel
@onready var _result_panel: Panel = $ResultPanel
@onready var _result_title: LocalizedLabel = $ResultPanel/VBox/ResultTitle
@onready var _result_stars: Label = $ResultPanel/VBox/StarsLabel
@onready var _result_stats: Label = $ResultPanel/VBox/StatsLabel
@onready var _btn_retry: LocalizedButton = $ResultPanel/VBox/HBox/BtnRetry
@onready var _btn_next: LocalizedButton = $ResultPanel/VBox/HBox/BtnNext
@onready var _btn_back: LocalizedButton = $ResultPanel/VBox/HBox/BtnBack

func _ready() -> void:
	if _back_button != null:
		_back_button.pressed.connect(_on_back_pressed)
	if _hint_button != null:
		_hint_button.pressed.connect(_on_hint_pressed)
	if _popup_close_button != null:
		_popup_close_button.pressed.connect(func() -> void: _popup_panel.visible = false)

	if _btn_retry != null:
		_btn_retry.pressed.connect(_on_retry_pressed)
	if _btn_next != null:
		_btn_next.pressed.connect(_on_next_pressed)
	if _btn_back != null:
		_btn_back.pressed.connect(_on_back_pressed)
		
	_popup_panel.visible = false
	_result_panel.visible = false

## Called by SceneManager when launched from the world map.
func setup_scene(params: Dictionary) -> void:
	var path: String = params.get("level_path", "") as String
	if not path.is_empty():
		var lvl: Resource = ResourceLoader.load(path)
		if lvl is MemoryBoardLevel:
			start_level(lvl as MemoryBoardLevel)
		else:
			push_error("MemoryBoard: Failed to load level from path: " + path)
	level_finished.connect(func(_r: PuzzleResult) -> void:
		GameManager.evaluate_unlocks()
		SceneManager.change_scene("res://ui/world_map/world_map.tscn"))
	exit_requested.connect(func() -> void:
		SceneManager.go_back())

func _process(delta: float) -> void:
	if _timer_active and _logic.state != MemoryBoardLogic.State.COMPLETE:
		_time_spent += delta
		_update_header()

func start_level(level: MemoryBoardLevel) -> void:
	_level = level
	_time_spent = 0.0
	_hints_used = 0
	_timer_active = true
	_is_resolving = false
	_result_panel.visible = false
	_popup_panel.visible = false
	
	var extra_flips: int = 0
	if GameManager != null and GameManager.has_chosen_faction():
		var fdata: FactionData = GameManager.get_faction_data()
		if fdata != null:
			extra_flips = fdata.extra_flip_allowance
			
	_logic.load_level(level, -1, extra_flips)
	_build_grid()
	_update_header()

func _build_grid() -> void:
	for child: Node in _grid_container.get_children():
		child.queue_free()
	_cards.clear()
	
	_grid_container.columns = _level.grid_columns
	var logic_cards: Array[MemoryBoardLogic.CardItem] = _logic.cards
	
	for lc: MemoryBoardLogic.CardItem in logic_cards:
		var card_inst: MemoryCard = card_scene.instantiate() as MemoryCard
		_grid_container.add_child(card_inst)
		card_inst.placeholder_card_back = placeholder_card_back
		card_inst.placeholder_card_front = placeholder_card_front
		card_inst.setup(lc.index, lc.concept_id, lc.card_type)
		card_inst.card_tapped.connect(_on_card_tapped)
		card_inst.card_long_pressed.connect(_on_card_long_pressed)
		_cards.append(card_inst)

func _on_card_tapped(index: int) -> void:
	if _is_resolving or _logic.state == MemoryBoardLogic.State.COMPLETE:
		return
		
	var res: Dictionary = _logic.flip(index)
	if not res.get("success", false):
		return
		
	_cards[index].flip_to(true, true)
	_update_header()
	
	if res.get("matched", false):
		var pair_idx: Array = res.get("pair_indices", []) as Array
		for idx: Variant in pair_idx:
			_cards[int(idx)].is_matched = true
			_cards[int(idx)]._update_visuals()
		if res.get("complete", false):
			_on_level_completed()
	elif res.get("state", MemoryBoardLogic.State.IDLE) == MemoryBoardLogic.State.RESOLVING:
		_is_resolving = true
		var pair_idx: Array = res.get("pair_indices", []) as Array
		for idx: Variant in pair_idx:
			_cards[int(idx)].shake()
		
		# Delay 0.8s then resolve mismatch
		get_tree().create_timer(0.8).timeout.connect(func() -> void:
			var reset_indices: Array[int] = _logic.resolve_mismatch()
			for idx: int in reset_indices:
				if idx >= 0 and idx < _cards.size():
					_cards[idx].flip_to(false, true)
			_is_resolving = false
		)

func _on_card_long_pressed(_idx: int, concept_id: StringName) -> void:
	var hint_text: String = Localization.translate("concept." + str(concept_id) + ".hint")
	_popup_label.text = hint_text
	_popup_panel.visible = true

func _on_hint_pressed() -> void:
	if _is_resolving or _logic.state == MemoryBoardLogic.State.COMPLETE:
		return
	var pair: Array[int] = _logic.get_hint_pair()
	if pair.size() == 2:
		_hints_used += 1
		var c1: MemoryCard = _cards[pair[0]]
		var c2: MemoryCard = _cards[pair[1]]
		c1.flip_to(true, true)
		c2.flip_to(true, true)
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			if not c1.is_matched:
				c1.flip_to(false, true)
			if not c2.is_matched:
				c2.flip_to(false, true)
		)


func _update_header() -> void:
	if _level != null:
		_title_label.set_localized(_level.title_key)
	_moves_label.set_localized("ui.memory.moves", {"count": _logic.moves})
	var sec: int = int(_time_spent)
	_timer_label.set_localized("ui.memory.time", {"seconds": sec})

func _on_level_completed() -> void:
	_timer_active = false
	var stars: int = _logic.calculate_stars()
	
	var res: PuzzleResult = PuzzleResult.new()
	res.puzzle_id = _level.id
	res.completed = true
	res.stars = stars
	res.moves = _logic.moves
	res.time_seconds = _time_spent
	res.hints_used = _hints_used
	
	if GameManager != null:
		GameManager.register_puzzle_result(res)
		
	level_finished.emit(res)
	
	_result_title.set_localized("ui.memory.level_complete")
	_result_stars.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	_result_stats.text = Localization.translate("ui.memory.result_stats", {"moves": _logic.moves, "time": "%.1f" % _time_spent})
	_result_panel.visible = true

func _on_retry_pressed() -> void:
	if _level != null:
		start_level(_level)

func _on_next_pressed() -> void:
	exit_requested.emit()

func _on_back_pressed() -> void:
	exit_requested.emit()
