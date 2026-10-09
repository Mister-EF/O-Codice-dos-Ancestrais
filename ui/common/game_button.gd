## Touch-sized localized button with press feedback and settings-aware haptics.
class_name GameButton
extends LocalizedButton


func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y, 88.0)
	_apply_game_button_style()
	pressed.connect(_on_game_button_pressed)
	super._ready()


func _apply_game_button_style() -> void:
	var catalog: AssetCatalog = load("res://data/asset_catalog.tres") as AssetCatalog
	if catalog != null and catalog.button_texture != null:
		var style_norm: StyleBoxTexture = StyleBoxTexture.new()
		style_norm.texture = catalog.button_texture
		style_norm.texture_margin_left = 16.0
		style_norm.texture_margin_top = 16.0
		style_norm.texture_margin_right = 16.0
		style_norm.texture_margin_bottom = 16.0
		var style_press: StyleBoxTexture = style_norm.duplicate() as StyleBoxTexture
		style_press.modulate_color = Color(0.8, 0.8, 0.8)
		var style_hover: StyleBoxTexture = style_norm.duplicate() as StyleBoxTexture
		style_hover.modulate_color = Color(1.15, 1.15, 1.15)
		add_theme_stylebox_override("normal", style_norm)
		add_theme_stylebox_override("hover", style_hover)
		add_theme_stylebox_override("pressed", style_press)
		add_theme_stylebox_override("focus", style_norm)
		add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	else:
		add_theme_stylebox_override("normal", _style(Color(0.13, 0.18, 0.29)))
		add_theme_stylebox_override("hover", _style(Color(0.19, 0.27, 0.41)))
		add_theme_stylebox_override("pressed", _style(Color(0.08, 0.11, 0.19)))
		add_theme_stylebox_override("disabled", _style(Color(0.10, 0.12, 0.17)))


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
