## MemoryCard — Puzzle card using moldura-carta.png for card front and verso-carta.png for card back.
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
var _content_margin: MarginContainer
var _content: Label
var _icon: TextureRect
var _detail_popup: PopupPanel


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(110.0, 140.0)
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_FILL
	focus_mode = Control.FOCUS_NONE

	# Transparent stylebox so textures render edge-to-edge
	var clear_style: StyleBoxEmpty = StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", clear_style)
	add_theme_stylebox_override("hover", clear_style)
	add_theme_stylebox_override("pressed", clear_style)
	add_theme_stylebox_override("disabled", clear_style)
	add_theme_stylebox_override("focus", clear_style)

	# Main card texture (moldura-carta.png or verso-carta.png)
	_face = TextureRect.new()
	_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face)

	# Margin container ensuring text/icon stays inside moldura-carta.png frame
	_content_margin = MarginContainer.new()
	_content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content_margin.add_theme_constant_override("margin_left", 14)
	_content_margin.add_theme_constant_override("margin_right", 14)
	_content_margin.add_theme_constant_override("margin_top", 16)
	_content_margin.add_theme_constant_override("margin_bottom", 16)
	_content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content_margin)

	var content_vbox: VBoxContainer = VBoxContainer.new()
	content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_margin.add_child(content_vbox)

	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(54.0, 54.0)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.visible = false
	content_vbox.add_child(_icon)

	_content = Label.new()
	_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(_content)

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
	modulate.a = 0.6
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.12)
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
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
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

	var catalog: AssetCatalog = load("res://data/asset_catalog.tres") as AssetCatalog
	var visible_face: bool = _face_up or _matched or _hint_revealed

	# Determine Back and Front textures (verso-carta.png & moldura-carta.png)
	var back_tex: Texture2D = catalog.card_back if (catalog != null and catalog.card_back != null) else placeholder_card_back
	var front_tex: Texture2D = catalog.card_frame if (catalog != null and catalog.card_frame != null) else placeholder_card_front

	if not visible_face:
		# Card Backside (verso-carta.png)
		_face.texture = back_tex
		_face.visible = back_tex != null
		_icon.visible = false
		_content.visible = false
	else:
		# Card Frontside (moldura-carta.png framing the concept)
		_face.texture = front_tex
		_face.visible = front_tex != null

		match card_data.card_type:
			MemoryCardData.CardType.NAME:
				_icon.visible = false
				_content.visible = true
				_content.text = Localization.translate(card_data.concept.name_key)
				_content.add_theme_font_size_override("font_size", 15)
				_content.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08))

			MemoryCardData.CardType.DEFINITION:
				_icon.visible = false
				_content.visible = true
				_content.text = Localization.translate(card_data.concept.definition_key)
				_content.add_theme_font_size_override("font_size", 11)
				_content.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08))

			MemoryCardData.CardType.ICON:
				var icon_tex: Texture2D = card_data.concept.icon
				if icon_tex == null and catalog != null:
					if card_data.concept.id == &"docker":
						icon_tex = catalog.docker_icon
					elif card_data.concept.id == &"git":
						icon_tex = catalog.git_icon

				if icon_tex != null:
					_icon.texture = icon_tex
					_icon.visible = true
					_content.visible = false
				else:
					_icon.visible = false
					_content.visible = true
					_content.text = Localization.translate(card_data.concept.name_key)
					_content.add_theme_font_size_override("font_size", 14)
					_content.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08))
