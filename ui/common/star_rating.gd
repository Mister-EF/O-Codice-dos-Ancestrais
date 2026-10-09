## Compact localized star progress label.
class_name StarRating
extends LocalizedLabel


func set_rating(earned: int, total: int) -> void:
	set_localized("ui.stars_progress", {"earned": earned, "total": total})
