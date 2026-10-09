## Builds the shared UI theme without requiring bundled font or artwork assets.
class_name GameTheme
extends Resource

@export var placeholder_font: Font


func build_theme() -> Theme:
	var result: Theme = Theme.new()
	if placeholder_font != null:
		result.default_font = placeholder_font
	result.default_font_size = 18
	var panel: StyleBoxFlat = StyleBoxFlat.new()
	panel.bg_color = Color(0.075, 0.09, 0.15, 0.98)
	panel.border_color = Color(0.35, 0.43, 0.6)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(16)
	result.set_stylebox("panel", "PanelContainer", panel)
	return result
