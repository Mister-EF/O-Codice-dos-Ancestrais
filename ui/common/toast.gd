## Brief localized notification with a fade-and-rise animation.
class_name Toast
extends PanelContainer

@export var placeholder_vfx: Texture2D

var _label: LocalizedLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(0.09, 0.12, 0.19, 0.98)
	box.border_color = Color(0.95, 0.75, 0.30)
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	add_theme_stylebox_override("panel", box)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var image: TextureRect = TextureRect.new()
	image.texture = placeholder_vfx
	image.custom_minimum_size = Vector2(48.0, 48.0)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.visible = image.texture != null
	row.add_child(image)
	_label = LocalizedLabel.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_label)
	visible = false


func show_key(key: String, params: Dictionary = {}) -> void:
	_label.set_localized(key, params)
	visible = true
	modulate.a = 0.0
	position.y += 12.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(self, "position:y", position.y - 12.0, 0.18)
	tween.tween_interval(2.4)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void: visible = false)
