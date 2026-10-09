## Reusable localized modal confirmation dialog.
class_name ConfirmDialog
extends PopupPanel

signal confirmed
signal cancelled

var _title: LocalizedLabel
var _message: LocalizedLabel
var _confirm: GameButton
var _cancel: GameButton
var _confirm_key: String = ""


func _ready() -> void:
	var panel: GamePanel = GamePanel.new()
	panel.custom_minimum_size = Vector2(440.0, 260.0)
	add_child(panel)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)
	_title = LocalizedLabel.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	layout.add_child(_title)
	_message = LocalizedLabel.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_message)
	_confirm = GameButton.new()
	_confirm.pressed.connect(_on_confirm)
	layout.add_child(_confirm)
	_cancel = GameButton.new()
	_cancel.pressed.connect(_on_cancel)
	layout.add_child(_cancel)
	popup_hide.connect(func() -> void: cancelled.emit())


func ask(title_key: String, message_key: String, confirm_key: String, cancel_key: String, params: Dictionary = {}) -> void:
	_title.set_localized(title_key)
	_message.set_localized(message_key, params)
	_confirm_key = confirm_key
	_confirm.set_localized(confirm_key)
	_cancel.set_localized(cancel_key)
	popup_centered(Vector2i(460, 280))


func _on_confirm() -> void:
	hide()
	confirmed.emit()


func _on_cancel() -> void:
	hide()
	cancelled.emit()
