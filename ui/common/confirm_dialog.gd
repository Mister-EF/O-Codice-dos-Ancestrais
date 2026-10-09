## Reusable confirmation dialog with localized title, message, and actions.
class_name ConfirmDialog
extends PanelContainer

signal confirmed
signal cancelled

@onready var _title_lbl: LocalizedLabel = $VBox/TitleLabel
@onready var _msg_lbl: LocalizedLabel = $VBox/MessageLabel
@onready var _btn_confirm: LocalizedButton = $VBox/HBox/BtnConfirm
@onready var _btn_cancel: LocalizedButton = $VBox/HBox/BtnCancel

func _ready() -> void:
	visible = false
	if _btn_confirm != null:
		_btn_confirm.pressed.connect(_on_confirm)
	if _btn_cancel != null:
		_btn_cancel.pressed.connect(_on_cancel)

func popup_dialog(title_key: String, message_key: String, confirm_key: String = "ui.confirm", cancel_key: String = "ui.cancel") -> void:
	_title_lbl.set_localized(title_key)
	_msg_lbl.set_localized(message_key)
	_btn_confirm.set_localized(confirm_key)
	_btn_cancel.set_localized(cancel_key)
	visible = true

func _on_confirm() -> void:
	visible = false
	confirmed.emit()

func _on_cancel() -> void:
	visible = false
	cancelled.emit()
