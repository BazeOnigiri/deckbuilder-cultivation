class_name EventDefinition
extends Resource
## Rencontre de cultivation 遇 entre deux goulots : un recit et 2 a 3 choix. N'apparait que si la run remplit ses
## conditions (royaume minimum, artefacts possedes), au plus une fois par partie.

@export var id: StringName = &""
@export var title_key: String = ""
@export var text_key: String = ""
## Caractere dessine sur le rouleau et dans le compendium (police des sceaux).
@export var glyph: String = ""
## Numero du royaume a partir duquel la rencontre peut apparaitre.
@export var min_realm: int = 1
@export var min_artifacts: int = 0
@export var choices: Array[EventChoice] = []


func is_valid() -> bool:
	return (not id.is_empty() and not title_key.is_empty() and not text_key.is_empty() and min_realm >= 1
		and min_artifacts >= 0 and choices.size() >= 2 and choices.size() <= 3
		and choices.all(func(choice: EventChoice) -> bool: return choice != null and choice.is_valid()))


func can_appear(run: RunState) -> bool:
	return run.progress.realm_number() >= min_realm and run.artifacts.size() >= min_artifacts
