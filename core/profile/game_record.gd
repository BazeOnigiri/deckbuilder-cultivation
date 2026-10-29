class_name GameRecord
extends RefCounted
## Une partie terminee, gardee dans l'historique du profil. Tout est reference par id texte.

## Date en secondes Unix.
var played_at: int = 0
var won: bool = false
var realm_id: String = ""
var bottleneck_id: String = ""
var bottlenecks_cleared: int = 0
var best_hand_score: int = 0
var best_hand_id: String = ""
var favorite_hand_id: String = ""
var artifacts: Array[String] = []
var legacies: Array[String] = []
## Graine de la run, vide si elle est inconnue (partie reprise d'une ancienne sauvegarde).
var seed_text: String = ""


func to_dict() -> Dictionary:
	return {
		"played_at": played_at,
		"won": won,
		"realm": realm_id,
		"bottleneck": bottleneck_id,
		"cleared": bottlenecks_cleared,
		"best_hand_score": best_hand_score,
		"best_hand": best_hand_id,
		"favorite_hand": favorite_hand_id,
		"artifacts": artifacts,
		"legacies": legacies,
		"seed": seed_text,
	}


## Le fichier vient du disque du joueur : un champ absent ou de mauvais type prend sa valeur neutre.
static func from_dict(data: Dictionary) -> GameRecord:
	var record := GameRecord.new()
	record.played_at = maxi(0, SaveData.int_of(data, "played_at"))
	record.won = data.get("won", false) is bool and data["won"]
	record.realm_id = _text(data, "realm")
	record.bottleneck_id = _text(data, "bottleneck")
	record.bottlenecks_cleared = maxi(0, SaveData.int_of(data, "cleared"))
	record.best_hand_score = maxi(0, SaveData.int_of(data, "best_hand_score"))
	record.best_hand_id = _text(data, "best_hand")
	record.favorite_hand_id = _text(data, "favorite_hand")
	record.artifacts = SaveData.string_list(data.get("artifacts"))
	record.legacies = SaveData.string_list(data.get("legacies"))
	record.seed_text = _text(data, "seed")
	return record


static func _text(data: Dictionary, key: String) -> String:
	var value: Variant = data.get(key, "")
	return value if value is String else ""
