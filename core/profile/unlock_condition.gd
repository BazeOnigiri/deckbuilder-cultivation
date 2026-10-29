class_name UnlockCondition
extends Resource
## Condition de profil ou de partie, en donnees : deblocage d'un contenu (UnlockRule) ou succes (AchievementDefinition).
## Les conditions de partie (WIN_NO_PURCHASE et suivantes) lisent la run en cours : fausses hors d'une run.

## Ajouter a la fin seulement : les .tres stockent le numero.
enum Kind {
	WINS, ## count parties gagnees
	REALM, ## royaume numero count atteint
	HAND_PLAYED, ## la main target jouee count fois
	ARTIFACTS_BOUGHT, ## count artefacts achetes en boutique, toutes parties
	TRIBULATIONS_WON, ## count tribulations vaincues, toutes parties
	BEST_SCORE, ## un coup d'au moins count points
	GAMES, ## count parties commencees
	WIN_NO_PURCHASE, ## cette partie gagnee sans acheter d'artefact
	ONE_HAND_CLEARS, ## count goulots franchis en une seule main, dans cette partie
	ARTIFACTS_OWNED, ## count artefacts possedes en meme temps
	LEGACIES_OWNED, ## count heritages possedes en meme temps
	BOTTLENECKS_SKIPPED, ## count goulots passes dans cette partie
	EVENTS_SEEN, ## count rencontres differentes vecues, toutes parties
}

@export var kind: Kind = Kind.WINS
## id de la main pour HAND_PLAYED, vide sinon.
@export var target: StringName = &""
@export var count: int = 1


func is_valid() -> bool:
	return count > 0 and (kind != Kind.HAND_PLAYED or not target.is_empty())


func is_met(ctx: UnlockContext) -> bool:
	var profile := ctx.profile
	match kind:
		Kind.WINS:
			return profile.runs_won >= count
		Kind.REALM:
			return profile.best_realm >= count
		Kind.HAND_PLAYED:
			return profile.hands.count_of(String(target)) >= count
		Kind.ARTIFACTS_BOUGHT:
			return profile.total_purchases() >= count
		Kind.TRIBULATIONS_WON:
			return profile.total_tribulation_wins() >= count
		Kind.BEST_SCORE:
			return profile.best_hand_score >= count
		Kind.GAMES:
			return profile.runs_started >= count
		Kind.WIN_NO_PURCHASE:
			return ctx.run != null and ctx.won and ctx.purchases == 0
		Kind.ONE_HAND_CLEARS:
			return ctx.run != null and ctx.one_hand_clears >= count
		Kind.ARTIFACTS_OWNED:
			return ctx.run != null and ctx.run.artifacts.size() >= count
		Kind.LEGACIES_OWNED:
			return ctx.run != null and ctx.run.legacies.size() >= count
		Kind.BOTTLENECKS_SKIPPED:
			return ctx.run != null and ctx.run.stats.bottlenecks_skipped >= count
		Kind.EVENTS_SEEN:
			return profile.seen.get(Compendium.KEYS[Compendium.Kind.EVENT], {}).size() >= count
	return false


## Texte de la condition pour le joueur (« Gagner 3 parties »). hands : pour nommer la main de HAND_PLAYED.
func describe(hands: Array[HandDefinition] = []) -> String:
	var key: String = "UNLOCK_" + Kind.keys()[kind]
	if kind == Kind.HAND_PLAYED:
		var hand_name := String(target)
		for hand: HandDefinition in hands:
			if hand.id == target:
				hand_name = tr(hand.name_key)
		return tr(key) % [hand_name, count]
	if kind == Kind.WIN_NO_PURCHASE:
		return tr(key)
	return tr(key) % count
