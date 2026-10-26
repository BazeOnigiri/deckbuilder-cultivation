class_name ShopPavilion
extends PanelContainer
## Cadre laque de la boutique : le panneau du Theme (type ShopPavilion), un second filet d'or
## en retrait et des coins ornes (equerre et losange) dessines dans _draw().


func _ready() -> void:
	theme_type_variation = &"ShopPavilion"


func _draw() -> void:
	var color := get_theme_color(&"line_color", &"ShopPavilion")
	var inset: float = get_theme_constant(&"inner_inset", &"ShopPavilion")
	var corner: float = get_theme_constant(&"corner_size", &"ShopPavilion")
	var inner := Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2)
	draw_rect(inner, color, false, 1.0)
	var corners: Array[Vector2] = [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]
	for point: Vector2 in corners:
		# Vers l'interieur du cadre depuis ce coin.
		var inward := (inner.get_center() - point).sign()
		var arm := inward * corner
		draw_polyline([point + Vector2(arm.x, 0), point, point + Vector2(0, arm.y)], color, 2.0)
		var tip := point + inward * corner * 0.55
		var half := corner * 0.2
		draw_colored_polygon([tip + Vector2(0, -half), tip + Vector2(half, 0), tip + Vector2(0, half), tip + Vector2(-half, 0)], color)
