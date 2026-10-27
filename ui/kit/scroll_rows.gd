class_name ScrollRows
extends RefCounted
## Lignes des rouleaux : « nom ........ valeur », le nom en legende, des points de suite a l'encre, la valeur a droite.
## Partagees par les statistiques, la Voie de cultivation, la fin de run et le resume d'une run sauvegardee.


## value_parts : la valeur, puis d'eventuels controles poses apres elle (icones).
static func row(name_key: String, value: String, extra: Array[Control] = []) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_child(SideColumn.make_label(&"ScrollCaption", name_key))
	var leader := InkLeader.new()
	leader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(leader)
	if not value.is_empty():
		var value_label := SideColumn.make_label(&"ScrollText")
		value_label.text = value
		line.add_child(value_label)
	for control: Control in extra:
		line.add_child(control)
	return line


## Points de suite, sur la ligne de base de la legende.
class InkLeader extends Control:
	func _draw() -> void:
		var color := get_theme_color(&"font_color", &"ScrollCaption")
		var gap: float = get_theme_constant(&"leader_gap", &"ScrollPanel")
		var y := size.y * 0.7
		var x := gap
		while x < size.x - gap:
			draw_circle(Vector2(x, y), 1.0, color)
			x += gap
