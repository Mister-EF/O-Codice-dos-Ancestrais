## Interactive memory card with localized content and long-press reinforcement.
class_name MemoryCard
extends Button

signal detail_requested(concept: ConceptData)

@export var placeholder_card_back: Texture2D
@export var placeholder_card_front: Texture2D

var card_data: MemoryCardData
var card_index: int = -1
var _face_up: bool = false
var _matched: bool = false
var _hint_revealed: bool = false
var _long_press_consumed: bool = false
var _long_press_timer: Timer
var _face: TextureRect
var _content: Label
var _detail_popup: PopupPanel


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(88.0, 88.0)
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_FILL
	focus_mode = Control.FOCUS_NONE
	add_theme_stylebox_override("normal", _make_style(Color(0.18, 0.22, 0.34)))
	add_theme_stylebox_override("hover", _make_style(Color(0.24, 0.31, 0.46)))
	add_theme_stylebox_override("pressed", _make_style(Color(0.13, 0.17, 0.28)))
	add_theme_stylebox_override("disabled", _make_style(Color(0.2, 0.48, 0.38)))
	_face = TextureRect.new()
	_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face)
	_content = Label.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_theme_font_size_override("font_size", 17)
	_content.add_theme_color_override("font_color", Color.WHITE)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.wait_time = 0.4
	_long_press_timer.timeout.connect(_on_long_press_timeout)
	add_child(_long_press_timer)
	_detail_popup = PopupPanel.new()
	var detail_label: Label = Label.new()
	detail_label.name = "Hint"
	detail_label.custom_minimum_size = Vector2(280.0, 80.0)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_popup.add_child(detail_label)
	add_child(_detail_popup)
	EventBus.language_changed.connect(_on_language_changed)
	pressed.connect(_on_pressed)
	_refresh_face()


func _exit_tree() -> void:
	if EventBus.language_changed.is_connected(_on_language_changed):
		EventBus.language_changed.disconnect(_on_language_changed)


func configure(data: MemoryCardData, index: int, initially_face_up: bool = false) -> void:
	card_data = data
	card_index = index
	_face_up = initially_face_up
	if is_inside_tree():
		_refresh_face()


func set_face_up(value: bool) -> void:
	if _face_up == value:
		return
	_face_up = value
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.08)
	tween.tween_callback(_refresh_face)
	tween.tween_property(self, "scale:x", 1.0, 0.08)


func set_matched() -> void:
	_matched = true
	disabled = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func set_hint_revealed(value: bool) -> void:
	_hint_revealed = value
	_refresh_face()


func shake_mismatch() -> void:
	var origin: Vector2 = position
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", origin.x - 8.0, 0.04)
	tween.tween_property(self, "position:x", origin.x + 8.0, 0.04)
	tween.tween_property(self, "position:x", origin.x, 0.04)


func _gui_input(event: InputEvent) -> void:
	if _matched or card_data == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_long_press_consumed = false
			_long_press_timer.start()
		else:
			_long_press_timer.stop()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_long_press_consumed = false
			_long_press_timer.start()
		else:
			_long_press_timer.stop()


func _on_pressed() -> void:
	if _long_press_consumed or _matched:
		return
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.96, 0.96), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)


func _on_long_press_timeout() -> void:
	if card_data == null or _matched:
		return
	_long_press_consumed = true
	detail_requested.emit(card_data.concept)
	var detail_label: Label = _detail_popup.get_node("Hint") as Label
	detail_label.text = Localization.translate(card_data.concept.hint_key)
	_detail_popup.popup_centered(Vector2i(320, 120))


func _on_language_changed(_locale: String) -> void:
	_refresh_face()
	if is_instance_valid(_detail_popup) and _detail_popup.visible and card_data != null:
		var detail_label: Label = _detail_popup.get_node("Hint") as Label
		detail_label.text = Localization.translate(card_data.concept.hint_key)


func _refresh_face() -> void:
	if not is_instance_valid(_content) or card_data == null:
		return
	var visible_face: bool = _face_up or _matched or _hint_revealed
	var texture: Texture2D
	if visible_face:
		texture = placeholder_card_front
	else:
		texture = placeholder_card_back
	_face.texture = texture
	_face.visible = texture != null
	if not visible_face:
		_content.text = Localization.translate("ui.memory.card_back")
		return
	match card_data.card_type:
		MemoryCardData.CardType.NAME:
			_content.text = Localization.translate(card_data.concept.name_key)
		MemoryCardData.CardType.DEFINITION:
			_content.text = Localization.translate(card_data.concept.definition_key)
		MemoryCardData.CardType.ICON:
			if card_data.concept.placeholder_icon != null:
				_face.texture = card_data.concept.placeholder_icon
				_face.visible = true
				_content.text = Localization.translate(card_data.concept.name_key)
			else:
				_content.text = Localization.translate("ui.memory.icon_placeholder", {
					"name": Localization.translate(card_data.concept.name_key),
				})
	_content.add_theme_color_override("font_color", Color(0.95, 0.94, 0.86) if visible_face else Color.WHITE)


func _make_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.55, 0.62, 0.82)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style
