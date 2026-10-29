class_name EventCost
extends Resource
## Cout d'un choix de rencontre, paye avant son issue. Refuse (blocked_reason) quand la run ne peut pas le payer.

## Ajouter a la fin seulement : les .tres stockent le numero.
enum Kind {
	STONES, ## amount pierres
	CARDS, ## amount cartes du paquet detruites au hasard ; le paquet garde au moins une main pleine
	ARTIFACT, ## amount artefacts possedes perdus au hasard
	HANDS, ## amount mains de moins au prochain goulot (au moins une reste)
}

@export var kind: Kind = Kind.STONES
@export var amount: int = 1


func is_valid() -> bool:
	return amount > 0


## Cle du texte qui dit pourquoi le cout ne peut pas etre paye, "" s'il peut l'etre.
func blocked_reason(run: RunState) -> String:
	match kind:
		Kind.STONES:
			return "" if run.stones >= amount else "EVENT_BLOCK_STONES"
		Kind.CARDS:
			return "" if run.cards().size() - amount >= run.round_rules().hand_size else "EVENT_BLOCK_CARDS"
		Kind.ARTIFACT:
			return "" if run.artifacts.size() >= amount else "EVENT_BLOCK_ARTIFACT"
	return ""


func pay(run: RunState, rng: RandomNumberGenerator) -> void:
	match kind:
		Kind.STONES:
			run.stones -= amount
		Kind.CARDS:
			var cards := run.cards()
			RngUtils.shuffle(cards, rng)
			run.remove_cards(cards.slice(0, amount))
		Kind.ARTIFACT:
			for i: int in amount:
				run.lose_artifact(rng.randi_range(0, run.artifacts.size() - 1))
		Kind.HANDS:
			run.hand_penalty += amount


## Texte du cout pour le joueur.
func describe() -> String:
	return tr("EVENT_COST_" + Kind.keys()[kind]) % amount
