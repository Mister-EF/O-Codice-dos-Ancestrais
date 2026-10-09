## Shared flat, rounded panel style.
class_name GamePanel
extends PanelContainer


func _ready() -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(0.075, 0.09, 0.15, 0.98)
	box.border_color = Color(0.35, 0.43, 0.6)
	box.set_border_width_all(2)
	box.set_corner_radius_all(16)
	box.content_margin_left = 18.0
	box.content_margin_right = 18.0
	box.content_margin_top = 16.0
	box.content_margin_bottom = 16.0
	add_theme_stylebox_override("panel", box)
