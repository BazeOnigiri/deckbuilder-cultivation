class_name ElementStyles
extends RefCounted
## Styles des elements, charges une fois depuis ui/cards/styles/. Ajouter un element = ajouter un fichier.

const DIR := "res://ui/cards/styles"

static var _by_element: Dictionary = {}


static func of(element: Element.Type) -> ElementStyle:
	if _by_element.is_empty():
		for res: Resource in ContentLoader.load_all(DIR):
			var style := res as ElementStyle
			if style == null:
				push_warning("Ressource ignoree dans %s : %s" % [DIR, res.resource_path])
				continue
			_by_element[style.element] = style
	return _by_element.get(element) as ElementStyle