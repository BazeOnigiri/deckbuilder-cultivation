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
@export var detector: HandDetector


func is_valid() -> bool:
	return (not id.is_empty() and not name_key.is_empty() and detector != null
		and base_qi >= 0 and base_comprehension > 0)