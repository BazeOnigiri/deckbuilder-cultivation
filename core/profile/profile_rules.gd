class_name ProfileRules
extends Resource
## Regles du profil en donnees (content/rules/profil_base.tres).

@export var id: StringName = &""
## Nombre de parties terminees gardees dans l'historique ; les plus anciennes sortent en premier.
@export var history_size: int = 20
