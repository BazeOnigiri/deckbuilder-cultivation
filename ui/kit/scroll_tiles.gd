class_name ScrollTiles
extends RefCounted
## Chiffres mis en scene sur les rouleaux : tuile encadree d'un trait de sceau (gros chiffre, legende dessous)
## et barre d'encre pour comparer des comptes. Partages par les statistiques et la Voie de cultivation.


## glyph : sceau decoratif pose a cote du chiffre (police des sceaux), vide pour aucun.
static func stat(value: String, caption_key: String, glyph: String = "") -> PanelContainer:
	var tile := PanelContainer.new()
	tile.theme_type_variation = &"StatTile"
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	var number := SideColumn.make_label(&"StatNumber")
	number.text = value
	top.add_child(number)
	if not glyph.is_empty():
		var seal := SideColumn.make_label(&"PathSeal")
		seal.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		seal.text = glyph
		top.add_child(seal)
	column.add_child(top)
	var caption := SideColumn.make_label(&"ScrollCaption", caption_key)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	tile.add_child(column)
	tile.custom_minimum_size.x = tile.get_theme_constant(&"width", &"StatTile")
	return tile


## Une ligne « nom  ████░░  compte », la barre remplie a count / max_count.
static func bar(label: String, count: int, max_count: int) -> HBoxContainer:
	var line := HBoxContainer.new()
	var name_label := SideColumn.make_label(&"ScrollText")
	name_label.text = label
	name_label.custom_minimum_size.x = line.get_theme_constant(&"name_width", &"InkBar")
	line.add_child(name_label)
	var ink := InkBar.new()
	ink.fill = 0.0 if max_count <= 0 else float(count) / max_count
	ink.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ink.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ink.custom_minimum_size.y = line.get_theme_constant(&"height", &"InkBar")
	line.add_child(ink)
	var count_label := SideColumn.make_label(&"ScrollText")
	count_label.text = str(count)
	line.add_child(count_label)
	return line


class InkBar extends Control:
	## 0 = vide, 1 = pleine.
	var fill: float = 0.0

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), get_theme_color(&"track", &"InkBar"))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(fill, 0.0, 1.0), size.y)), get_theme_color(&"fill", &"InkBar"))
