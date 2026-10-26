class_name HandLayout
extends RefCounted
## Place une main en eventail. Calcul pur, sans noeud : teste sans scene.


## Pour chaque carte : Vector3(x, y, angle en radians) de son centre, par rapport au centre de la main.
## Les cartes se resserrent quand la largeur disponible ne suffit pas.
static func slots(count: int, available_width: float, card_width: float, feel: HandFeel) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if count <= 0:
		return result
	var spacing: float = card_width + feel.gap
	if count > 1:
		spacing = clampf((available_width - card_width) / (count - 1), 0.0, spacing)
	for i: int in count:
		# t va de -1 (carte de gauche) a 1 (carte de droite).
		var t: float = 0.0 if count == 1 else float(i) / (count - 1) * 2.0 - 1.0
		var x: float = (i - (count - 1) / 2.0) * spacing
		result.append(Vector3(x, t * t * feel.arc_height, t * deg_to_rad(feel.fan_angle)))
	return result
