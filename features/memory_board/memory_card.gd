## Card UI view for Memory Board puzzle.
class_name MemoryCard
extends Control

signal card_tapped(index: int)
signal card_long_pressed(index: int, concept_id: StringName)

@export var placeholder_card_back: Texture2D = null
@export var placeholder_card_front: Texture2D = null

var card_index: int = -1
var concept_id: StringName = &""
var card_type: String = "name" # "name", "definition", "icon"
var is_face_up: bool = false
var is_matched: bool = false

var _long_press_timer: float = 0.0
var _is_pressing: bool = false
var _long_press_triggered: bool = false

@onready var _background: Panel = $Background
@onready var _label: Label = $Label
@onready var _texture_rect: TextureRect = $TextureRect

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(88, 88)
	if EventBus.has_signal("language_changed"):
		EventBus.language_changed.connect(_on_language_changed)
	_update_visuals()


func _process(delta: float) -> void:
	if _is_pressing and not _long_press_triggered:
		_long_press_timer += delta
		if _long_press_timer >= 0.4:
			_long_press_triggered = true
			card_long_pressed.emit(card_index, concept_id)

func me_ready() -> void:
	pass

func setup(idx: int, p_concept_id: StringName, p_type: String) -> void:
	card_index = idx
	concept_id = p_concept_id
	card_type = p_type
	is_face_up = false
	is_matched = false
	_update_visuals()

func _gui_input(event: InputEvent) -> void:
	if is_matched:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressing = true
			_long_press_timer = 0.0
			_long_press_triggered = false
		else:
			if _is_pressing and not _long_press_triggered:
				card_tapped.emit(card_index)
			_is_pressing = false

func flip_to(face_up: bool, animate: bool = true) -> void:
	if is_face_up == face_up:
		return
	is_face_up = face_up
	if animate:
		var tween: Tween = create_tween()
		tween.tween_property(self, "scale:x", 0.0, 0.1)
		tween.tween_callback(_update_visuals)
		tween.tween_property(self, "scale:x", 1.0, 0.1)
	else:
		_update_visuals()

func shake() -> void:
	var tween: Tween = create_tween()
	var orig_pos: Vector2 = position
	tween.tween_property(self, "position:x", orig_pos.x - 6.0, 0.05)
	tween.tween_property(self, "position:x", orig_pos.x + 6.0, 0.05)
	tween.tween_property(self, "position:x", orig_pos.x - 3.0, 0.05)
	tween.tween_property(self, "position:x", orig_pos.x, 0.05)

func _update_visuals() -> void:
	if not is_inside_tree() or _background == null:
		return
		
	if is_face_up or is_matched:
		modulate = Color(0.7, 1.0, 0.7) if is_matched else Color(1.0, 1.0, 1.0)
		_texture_rect.visible = false
		_label.visible = true
		
		if card_type == "name":
			_label.text = Localization.translate("concept." + str(concept_id) + ".name")
		elif card_type == "definition":
			_label.text = Localization.translate("concept." + str(concept_id) + ".definition")
		else:
			_label.text = "[" + str(concept_id) + "]"
	else:
		modulate = Color(0.9, 0.9, 0.9)
		_texture_rect.visible = (placeholder_card_back != null)
		_label.visible = false
		if placeholder_card_back != null:
			_texture_rect.texture = placeholder_card_back

func _on_language_changed(_locale: String) -> void:
	_update_visuals()
