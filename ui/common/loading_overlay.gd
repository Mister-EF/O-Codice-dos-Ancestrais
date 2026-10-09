## Reusable full-screen loading overlay with optional placeholder art.
class_name LoadingOverlay
extends Control

@export var placeholder_texture: Texture2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.06, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	stack.position = Vector2(-180.0, -70.0)
	stack.custom_minimum_size = Vector2(360.0, 140.0)
	stack.add_theme_constant_override("separation", 16)
	add_child(stack)
	var image: TextureRect = TextureRect.new()
	image.texture = placeholder_texture
	image.custom_minimum_size = Vector2(96.0, 96.0)
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stack.add_child(image)
	var label: LocalizedLabel = LocalizedLabel.new()
	label.translation_key = "ui.loading"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(label)
