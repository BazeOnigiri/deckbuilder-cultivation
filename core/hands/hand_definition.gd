class_name HandDefinition
extends Resource
## Une main en donnees. Ajouter une main = ajouter un .tres dans content/hands/.

@export var id: String = ""
## Cle de traduction du nom affiche (utilisee avec tr()).
@export var name_key: String = ""
## Plus grand = plus fort. La main jouee prend la definition la plus prioritaire qui correspond.
@export var priority: int = 0
@export var base_qi: int = 0
@export var base_comprehension: int = 0
## Gain par niveau au-dessus du premier (manuels de technique).
@export var level_qi: int = 0
@export var level_comprehension: int = 0
@export var detector: HandDetector
## Exemple montre dans la Voie de cultivation : une carte par entree, x = element (Element.Type), y = rang.
@export var example: Array[Vector2i] = []


## Cartes de l'exemple, pretes a passer aux detecteurs.
func example_cards() -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for i: int in example.size():
		var data := CardData.create(StringName("%s_exemple_%d" % [id, i]), example[i].x as Element.Type, example[i].y)
		cards.append(CardInstance.new(i, data))
	return cards


func is_valid() -> bool:
	return (not id.is_empty() and not name_key.is_empty() and detector != null
		and base_qi >= 0 and base_comprehension > 0 and level_qi >= 0 and level_comprehension >= 0)

func qi_at(level: int) -> int:
	return base_qi + (level - 1) * level_qi


func comprehension_at(level: int) -> int:
	return base_comprehension + (level - 1) * level_comprehension