## Haptics — Wrapper for device haptic feedback, guarded by a settings flag.
## Call Haptics.vibrate() from anywhere; it will silently no-op when disabled
## or on platforms that don't support it.
class_name Haptics
extends RefCounted


## Trigger a short haptic pulse if haptics are enabled in settings.
static func vibrate(duration_ms: int = 50) -> void:
	if not GameManager.is_haptics_enabled():
		return
	Input.vibrate_handheld(duration_ms)
