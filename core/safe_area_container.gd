## SafeAreaContainer — A MarginContainer that automatically applies
## device safe area insets (notches, rounded corners, system bars).
## Place this as the root UI container in every screen.
class_name SafeAreaContainer
extends MarginContainer


func _ready() -> void:
	_apply_safe_area()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	_apply_safe_area()


func _apply_safe_area() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var screen_size: Vector2i = DisplayServer.screen_get_size()

	# If safe area covers the full screen, no insets needed.
	if safe_area.size.x <= 0 or safe_area.size.y <= 0:
		_set_margins(0, 0, 0, 0)
		return

	var left: int = safe_area.position.x
	var top: int = safe_area.position.y
	var right: int = maxi(0, screen_size.x - safe_area.position.x - safe_area.size.x)
	var bottom: int = maxi(0, screen_size.y - safe_area.position.y - safe_area.size.y)

	# Scale insets from physical pixels to viewport coordinates.
	var viewport_size: Vector2 = get_viewport_rect().size
	var scale_x: float = viewport_size.x / float(screen_size.x) if screen_size.x > 0 else 1.0
	var scale_y: float = viewport_size.y / float(screen_size.y) if screen_size.y > 0 else 1.0

	_set_margins(
		int(float(left) * scale_x),
		int(float(top) * scale_y),
		int(float(right) * scale_x),
		int(float(bottom) * scale_y),
	)


func _set_margins(left: int, top: int, right: int, bottom: int) -> void:
	add_theme_constant_override("margin_left", left)
	add_theme_constant_override("margin_top", top)
	add_theme_constant_override("margin_right", right)
	add_theme_constant_override("margin_bottom", bottom)
