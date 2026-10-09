## Toast notification popup.
class_name ToastNotification
extends PanelContainer

@onready var _label: Label = $Label

func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE

func show_message(text: String, duration: float = 2.0) -> void:
	if _label != null:
		_label.text = text
	modulate.a = 0.0
	visible = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void: visible = false)
