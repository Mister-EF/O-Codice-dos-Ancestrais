## Asynchronous scene transitions and back navigation for the application.
extends Node

@export var placeholder_transition_texture: Texture2D

var current_params: Dictionary = {}
var _history: Array[String] = []
var _back_handlers: Array[Callable] = []
var _transitioning: bool = false
var _overlay_layer: CanvasLayer
var _overlay: ColorRect
var _transition_art: TextureRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 128
	get_tree().root.add_child.call_deferred(_overlay_layer)
	_overlay = ColorRect.new()
	_overlay.color = Color(0.015, 0.02, 0.045, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.add_child(_overlay)
	if placeholder_transition_texture == null:
		var catalog: AssetCatalog = load("res://data/asset_catalog.tres") as AssetCatalog
		if catalog != null:
			placeholder_transition_texture = catalog.placeholder_transition_texture
	_transition_art = TextureRect.new()
	_transition_art.texture = placeholder_transition_texture
	_transition_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_transition_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_transition_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_transition_art)
	_overlay.resized.connect(_sync_transition_art)
	get_tree().root.set_meta("scene_manager_ready", true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		go_back()
		get_viewport().set_input_as_handled()


func change_scene(path: String, params: Dictionary = {}) -> void:
	if path.strip_edges().is_empty():
		push_error("SceneManager: scene path must not be empty.")
		return
	var active_path: String = get_tree().current_scene.scene_file_path if get_tree().current_scene != null else ""
	if not active_path.is_empty() and active_path != path:
		_history.append(active_path)
	_transition_to(path, params)


func replace_scene(path: String, params: Dictionary = {}) -> void:
	if path.strip_edges().is_empty():
		push_error("SceneManager: scene path must not be empty.")
		return
	_transition_to(path, params)


func go_back() -> void:
	if _transitioning:
		return
	if not _back_handlers.is_empty():
		var handler: Callable = _back_handlers.pop_back()
		if handler.is_valid():
			handler.call()
		return
	if _history.is_empty():
		return
	var previous: String = _history.pop_back()
	_transition_to(previous, {}, true)


func push_back_handler(handler: Callable) -> void:
	if handler.is_valid():
		_back_handlers.append(handler)


func pop_back_handler(handler: Callable) -> void:
	var index: int = _back_handlers.rfind(handler)
	if index >= 0:
		_back_handlers.remove_at(index)


func clear_history() -> void:
	_history.clear()


func _transition_to(path: String, params: Dictionary, threaded: bool = true) -> void:
	if _transitioning:
		return
	_transitioning = true
	current_params = params.duplicate(true)
	if _overlay == null or not is_instance_valid(_overlay):
		_transitioning = false
		push_error("SceneManager: transition overlay is not initialized.")
		return
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: Tween = create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, 0.18)
	await tween.finished
	if threaded:
		var request_error: Error = ResourceLoader.load_threaded_request(path)
		if request_error != OK and request_error != ERR_BUSY:
			_finish_transition_error("SceneManager: unable to request '%s': %s" % [path, error_string(request_error)])
			return
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().create_timer(0.03, true, false, true).timeout
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_FAILED:
			_finish_transition_error("SceneManager: threaded load failed for '%s'." % path)
			return
	var packed: PackedScene = ResourceLoader.load_threaded_get(path) as PackedScene if threaded else load(path) as PackedScene
	if packed == null:
		_finish_transition_error("SceneManager: '%s' is not a valid PackedScene." % path)
		return
	var change_error: Error = get_tree().change_scene_to_packed(packed)
	if change_error != OK:
		_finish_transition_error("SceneManager: unable to change to '%s': %s" % [path, error_string(change_error)])
		return
	await get_tree().process_frame
	var fade: Tween = create_tween()
	fade.tween_property(_overlay, "color:a", 0.0, 0.22)
	await fade.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transitioning = false


func _finish_transition_error(message: String) -> void:
	push_error(message)
	if is_instance_valid(_overlay):
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween: Tween = create_tween()
		tween.tween_property(_overlay, "color:a", 0.0, 0.18)
		await tween.finished
	_transitioning = false


func _sync_transition_art() -> void:
	if is_instance_valid(_transition_art):
		_transition_art.texture = placeholder_transition_texture
