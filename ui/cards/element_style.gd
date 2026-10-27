class_name ElementStyle
extends Resource
## Habillage d'un element : couleur et symbole. Couleur ET forme, pour le daltonisme.

@export var element: Element.Type
@export var color: Color = Color.WHITE
## Symbole blanc, teinte par color au dessin.
@export var icon: Texture2D
