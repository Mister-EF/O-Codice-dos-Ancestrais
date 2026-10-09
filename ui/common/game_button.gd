## Touch-sized localized button with press feedback and settings-aware haptics.
class_name GameButton
extends LocalizedButton


func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y, 88.0)
	add_theme_stylebox_override("normal", _style(Color(0.13, 0.18, 0.29)))
	add_theme_stylebox_override("hover", _style(Color(0.19, 0.27, 0.41)))
	add_theme_stylebox_override("pressed", _style(Color(0.08, 0.11, 0.19)))
	add_theme_stylebox_override("disabled", _style(Color(0.10, 0.12, 0.17)))
	pressed.connect(_on_game_button_pressed)
	super._ready()


func _on_game_button_pressed() -> void:
	Haptics.vibrate(35)
	pivot_offset = size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.96, 0.96), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)


func _style(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color(0.49, 0.58, 0.77)
	box.set_border_width_all(2)
	box.set_corner_radius_all(12)
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	return box
