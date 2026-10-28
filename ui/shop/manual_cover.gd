class_name ManualCover
extends RefCounted
## Couverture d'un manuel de technique, dessinee par le moteur : livre cousu a la chinoise (线装), reliure a droite,
## fil qui passe par les trous et fait le tour du dos, etiquette de titre (题签) avec le sinogramme de la main,
## motif de couverture. Couleurs et tailles dans le Theme (type ManualCover). Pas de noeud : ItemSlot l'appelle.


## Dessine le livre dans rect sur canvas. tier : couleur de la couverture (rarete), pattern : motif.
static func draw(canvas: CanvasItem, rect: Rect2, glyph: String, tier: int, pattern: ManualDefinition.Pattern,
		dimmed: bool) -> void:
	var theme_owner := canvas as Control
	var cover := theme_owner.get_theme_color(StringName("tier_%d" % tier), &"ManualCover")
	var ink := theme_owner.get_theme_color(&"pattern_color", &"ManualCover")
	var thread := theme_owner.get_theme_color(&"thread_color", &"ManualCover")
	var slip := theme_owner.get_theme_color(&"slip_color", &"ManualCover")
	var text := theme_owner.get_theme_color(&"slip_text_color", &"ManualCover")
	if dimmed:
		# Manuel trop cher : couleurs tirees vers le gris des emplacements inactifs.
		var grey := theme_owner.get_theme_color(&"disabled_color", &"ManualCover")
		var amount: float = theme_owner.get_theme_constant(&"dim_percent", &"ManualCover") / 100.0
		cover = cover.lerp(grey, amount)
		thread = thread.lerp(grey, amount)
		slip = slip.lerp(grey, amount)
	var spine: float = theme_owner.get_theme_constant(&"spine_width", &"ManualCover")
	var holes: int = theme_owner.get_theme_constant(&"holes", &"ManualCover")
	# Couverture, puis tranche des pages en bas (le livre a une epaisseur).
	var thickness: float = theme_owner.get_theme_constant(&"thickness", &"ManualCover")
	rect = rect.grow_individual(0, 0, -thickness, -thickness)
	canvas.draw_rect(Rect2(rect.position + Vector2.ONE * thickness, rect.size),
		theme_owner.get_theme_color(&"pages_color", &"ManualCover"))
	canvas.draw_rect(rect, cover)
	_draw_pattern(canvas, rect.grow_individual(0, 0, -spine, 0), pattern, ink)
	# Reliure : ligne des trous a spine / 2 du bord droit, fil vertical, fil qui passe sur le dos a chaque trou,
	# et tour des coins en haut et en bas.
	var x := rect.end.x - spine / 2.0
	var step := rect.size.y / (holes + 1)
	var width := maxf(1.0, spine / 6.0)
	canvas.draw_line(Vector2(x, rect.position.y + step), Vector2(x, rect.end.y - step), thread, width)
	for i: int in holes:
		var y := rect.position.y + step * (i + 1)
		canvas.draw_line(Vector2(x, y), Vector2(rect.end.x, y), thread, width)
		canvas.draw_circle(Vector2(x, y), width * 1.2, thread.darkened(0.4))
	canvas.draw_line(Vector2(x, rect.position.y + step), Vector2(x, rect.position.y), thread, width)
	canvas.draw_line(Vector2(x, rect.end.y - step), Vector2(x, rect.end.y), thread, width)
	# Etiquette de titre : bande claire en haut a gauche, le sinogramme de la main dedans.
	var slip_size := rect.size * Vector2(theme_owner.get_theme_constant(&"slip_width_percent", &"ManualCover"),
		theme_owner.get_theme_constant(&"slip_height_percent", &"ManualCover")) / 100.0
	var margin: float = theme_owner.get_theme_constant(&"slip_margin", &"ManualCover")
	var slip_rect := Rect2(rect.position + Vector2.ONE * margin, slip_size)
	canvas.draw_rect(slip_rect, slip)
	canvas.draw_rect(slip_rect.grow(-2), Color(text, 0.5), false, 1.0)
	var font := theme_owner.get_theme_font(&"font", &"ManualCover")
	var font_size: int = theme_owner.get_theme_font_size(&"font_size", &"ManualCover")
	var baseline: float = slip_rect.position.y + (slip_rect.size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2
	canvas.draw_string(font, Vector2(slip_rect.position.x, baseline), glyph, HORIZONTAL_ALIGNMENT_CENTER,
		slip_rect.size.x, font_size, text)


static func _draw_pattern(canvas: CanvasItem, area: Rect2, pattern: ManualDefinition.Pattern, ink: Color) -> void:
	match pattern:
		ManualDefinition.Pattern.CLOUDS:
			for row: int in 3:
				for col: int in 2:
					var center := area.position + area.size * Vector2(0.3 + col * 0.45, 0.2 + row * 0.33)
					canvas.draw_arc(center, area.size.x * 0.12, PI, TAU, 12, ink, 1.0)
					canvas.draw_arc(center + Vector2(area.size.x * 0.12, 0), area.size.x * 0.08, PI, TAU, 10, ink, 1.0)
		ManualDefinition.Pattern.WAVES:
			for row: int in 6:
				var y := area.position.y + area.size.y * (row + 0.5) / 6.0
				var points := PackedVector2Array()
				for i: int in 13:
					var t := i / 12.0
					points.append(Vector2(area.position.x + area.size.x * t, y + sin(t * TAU * 2.0) * 2.5))
				canvas.draw_polyline(points, ink, 1.0)
		ManualDefinition.Pattern.LATTICE:
			var cell := area.size.x / 4.0
			var y := area.position.y
			while y < area.end.y:
				canvas.draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), ink, 1.0)
				y += cell
			var x := area.position.x
			while x < area.end.x:
				canvas.draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), ink, 1.0)
				x += cell
		ManualDefinition.Pattern.COINS:
			for row: int in 4:
				for col: int in 3:
					var center := area.position + area.size * Vector2((col + 0.5) / 3.0, (row + 0.5) / 4.0)
					canvas.draw_arc(center, area.size.x * 0.1, 0.0, TAU, 14, ink, 1.0)
					var side := area.size.x * 0.06
					canvas.draw_rect(Rect2(center - Vector2.ONE * side / 2.0, Vector2.ONE * side), ink, false, 1.0)
