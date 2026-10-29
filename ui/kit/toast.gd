class_name Toast
extends MarginContainer
## Notification discrete en haut a droite : une infobulle qui se fond au bout de quelques secondes.
## Ne prend ni la souris ni le focus. Duree dans le Theme (InfoBubble/toast_ms).

const MARGIN := 16


static func achievement(parent: Control, title: String, description: String) -> void:
	var toast := Toast.new()
	toast.mouse_filter = MOUSE_FILTER_IGNORE
	toast.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT, PRESET_MODE_MINSIZE, MARGIN)
	var bubble := InfoBubble.build(title, description,
		[[TranslationServer.translate("UI_ACHIEVEMENT_BADGE"), parent.get_theme_color(&"qi_color", &"InfoBubble")]])
	bubble.mouse_filter = MOUSE_FILTER_IGNORE
	toast.add_child(bubble)
	parent.add_child(toast)
	var seconds := parent.get_theme_constant(&"toast_ms", &"InfoBubble") / 1000.0
	var tween := toast.create_tween()
	tween.tween_interval(seconds)
	tween.tween_property(toast, "modulate:a", 0.0, seconds * 0.2)
	tween.tween_callback(toast.queue_free)
