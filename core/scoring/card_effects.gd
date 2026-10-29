class_name CardEffects
extends RefCounted
## Effets des ameliorations, auras et talismans des cartes pour une main jouee, et ce que la main produit en plus du
## score. Ordre deterministe : cartes qui comptent dans l'ordre (amelioration puis aura, a chaque recompte), puis
## cartes gardees en main ; le pipeline les range ensuite par phase.


static func triggered_for(result: HandResult, held: Array[CardInstance]) -> Array[TriggeredEffect]:
	var triggered: Array[TriggeredEffect] = []
	for card: CardInstance in result.scoring_sequence():
		if card.enhancement != null and card.enhancement.scored_effect != null:
			triggered.append(TriggeredEffect.new(card.enhancement.scored_effect, card.enhancement, card))
		if card.edition != null and card.edition.score_effect != null:
			triggered.append(TriggeredEffect.new(card.edition.score_effect, card.edition, card))
	for card: CardInstance in held:
		if card.enhancement != null and card.enhancement.held_effect != null:
			for i: int in card.triggers():
				triggered.append(TriggeredEffect.new(card.enhancement.held_effect, card.enhancement, card))
	return triggered


## Pierres des cartes qui comptent, a chaque recompte.
static func stones_for(result: HandResult) -> int:
	var stones: int = 0
	for card: CardInstance in result.scoring_sequence():
		if card.enhancement != null:
			stones += card.enhancement.scored_stones
	return stones


## Niveaux gagnes par la main jouee : une fois par carte qui compte (un recompte ne le double pas).
static func level_ups(result: HandResult) -> int:
	var levels: int = 0
	for card: CardInstance in result.scoring_cards:
		if card.talisman != null:
			levels += card.talisman.scored_level_ups
	return levels


## Cartes qui se brisent apres avoir compte : un tirage par carte fragile, dans l'ordre des cartes.
static func roll_breaks(result: HandResult, rng: RandomNumberGenerator) -> Array[CardInstance]:
	var broken: Array[CardInstance] = []
	for card: CardInstance in result.scoring_cards:
		if card.enhancement != null and card.enhancement.break_chance > 0.0 and rng.randf() < card.enhancement.break_chance:
			broken.append(card)
	return broken


## Pierres des cartes encore en main quand le goulot est franchi.
static func held_stones(held: Array[CardInstance]) -> int:
	var stones: int = 0
	for card: CardInstance in held:
		if card.talisman != null:
			stones += card.talisman.held_stones
	return stones


## Pilules a creer pour ces cartes defaussees.
static func pills_on_discard(discarded: Array[CardInstance]) -> int:
	return discarded.filter(func(card: CardInstance) -> bool:
		return card.talisman != null and card.talisman.discard_pill).size()
