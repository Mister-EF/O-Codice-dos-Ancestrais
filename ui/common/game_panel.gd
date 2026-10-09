## Shared panel style supporting catalog panel_texture or translucent rounded frame.
class_name GamePanel
extends PanelContainer


func _ready() -> void:
	var catalog: AssetCatalog = load("res://data/asset_catalog.tres") as AssetCatalog
	if catalog != null and catalog.panel_texture != null:
		var style: StyleBoxTexture = StyleBoxTexture.new()
		style.texture = catalog.panel_texture
		style.texture_margin_left = 18.0
		style.texture_margin_top = 18.0
		style.texture_margin_right = 18.0
		style.texture_margin_bottom = 18.0
		style.content_margin_left = 20.0
		style.content_margin_right = 20.0
		style.content_margin_top = 18.0
		style.content_margin_bottom = 18.0
		add_theme_stylebox_override("panel", style)
	else:
		var box: StyleBoxFlat = StyleBoxFlat.new()
		box.bg_color = Color(0.08, 0.10, 0.16, 0.88)
		box.border_color = Color(0.42, 0.52, 0.72, 0.8)
		box.set_border_width_all(2)
		box.set_corner_radius_all(16)
		box.content_margin_left = 18.0
		box.content_margin_right = 18.0
		box.content_margin_top = 16.0
		box.content_margin_bottom = 16.0
		add_theme_stylebox_override("panel", box)
