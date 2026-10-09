## SceneManager — Handles screen transitions, back-stack navigation, and Android back button.
class_name SceneManagerAutoload
extends Node

signal scene_changed(new_scene_path: String)

@export var placeholder_transition_texture: Texture2D = null

var _back_stack: Array[Dictionary] = []
var _current_scene_path: String = ""
var _current_params: Dictionary = {}
var _is_transitioning: bool = false
var _overlay: ColorRect = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_overlay()

func _create_overlay() -> void:
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.layer = 128
	add_child(canvas_layer)
	
	_overlay = ColorRect.new()
	_overlay.color = Color(0.08, 0.08, 0.12, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(_overlay)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _is_transitioning:
		go_back()

func change_scene(path: String, params: Dictionary = {}, push_to_history: bool = true) -> void:
	if _is_transitioning or path.is_empty():
		return
	_is_transitioning = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if push_to_history and not _current_scene_path.is_empty():
		_back_stack.append({
			"path": _current_scene_path,
			"params": _current_params
		})
		
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, 0.2)
	tween.tween_callback(func() -> void:
		_perform_scene_change(path, params)
	)

func go_back() -> bool:
	if _back_stack.is_empty() or _is_transitioning:
		return false
	var prev: Dictionary = _back_stack.pop_back()
	change_scene(prev["path"] as String, prev.get("params", {}) as Dictionary, false)
	return true

func can_go_back() -> bool:
	return not _back_stack.is_empty()

func get_current_scene_path() -> String:
	return _current_scene_path

func get_current_params() -> Dictionary:
	return _current_params

func clear_history() -> void:
	_back_stack.clear()

func _perform_scene_change(path: String, params: Dictionary) -> void:
	_current_scene_path = path
	_current_params = params
	var tree: SceneTree = get_tree()
	var err: Error = tree.change_scene_to_file(path)
	if err != OK:
		push_error("SceneManager: Failed to load scene '%s'" % path)
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay.color.a = 0.0
		_is_transitioning = false
		return
		
	# Fade back in after current frame finishes
	tree.process_frame.connect(_on_scene_loaded, CONNECT_ONE_SHOT)

func _on_scene_loaded() -> void:
	var tree: SceneTree = get_tree()
	if tree.current_scene != null and tree.current_scene.has_method("setup_scene"):
		tree.current_scene.call("setup_scene", _current_params)
		
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, 0.2)
	tween.tween_callback(func() -> void:
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_is_transitioning = false
		scene_changed.emit(_current_scene_path)
	)
