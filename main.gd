## Boot scene waits one frame for autoload initialization before showing the menu.
extends Control


func _ready() -> void:
	await get_tree().process_frame
	SceneManager.clear_history()
	SceneManager.replace_scene("res://ui/main_menu/main_menu.tscn")
