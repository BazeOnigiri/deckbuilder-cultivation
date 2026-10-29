class_name StickRepeat
extends RefCounted
## Stick gauche de la manette : une fois la direction prise, le focus ne bouge plus avant delay_ms, tant que le
## stick reste penche. Revenir au centre rearme tout de suite. Sans ce delai le focus defile trop vite.

## Axes du stick gauche et seuil a partir duquel le stick est penche (le meme que ui_up, ui_down...).
const AXES: Array[int] = [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]
const THRESHOLD := 0.5

var delay_ms: int
var _last_ms := {}


func _init(p_delay_ms: int) -> void:
	delay_ms = p_delay_ms


## Faux si cet evenement doit etre ignore. Tout ce qui n'est pas le stick gauche passe.
func allow(event: InputEvent, now_ms: int) -> bool:
	var motion := event as InputEventJoypadMotion
	if motion == null or not AXES.has(motion.axis):
		return true
	var key := motion.axis * 10 + (1 if motion.axis_value > 0.0 else -1)
	if absf(motion.axis_value) < THRESHOLD:
		_last_ms.erase(motion.axis * 10 + 1)
		_last_ms.erase(motion.axis * 10 - 1)
		return true
	if _last_ms.has(key) and now_ms - _last_ms[key] < delay_ms:
		return false
	_last_ms[key] = now_ms
	return true
