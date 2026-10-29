class_name DebugActions
extends RefCounted
## Actions du menu debug (ui/debug). Chacune passe par les memes chemins que le jeu (RunState, ShopState, RunProgress)
## et refuse ce que le jeu refuserait (emplacements pleins, doublons). Logique pure, testable sans scene.

## Pierres donnees par le bouton « +pierres ».
const STONES_GRANT := 10


static func add_stones(run: RunState) -> void:
	run.stones += STONES_GRANT


## Un artefact deja possede ou un emplacement plein : refuse, comme en boutique. rules : regles de base de la boutique.
static func give_artifact(run: RunState, artifact: ArtifactDefinition, rules: ShopRules) -> bool:
	if run.artifact_slots_used() >= run.shop_rules(rules).max_artifacts:
		return false
	for owned: ArtifactDefinition in run.artifacts:
		if owned.id == artifact.id:
			return false
	run.add_artifact(artifact)
	return true


static func give_pill(run: RunState, pill: PillDefinition, rules: ShopRules) -> bool:
	if run.pills.size() >= run.shop_rules(rules).max_pills:
		return false
	run.pills.append(pill)
	return true


## Monte la main du manuel d'un niveau.
static func give_manual(run: RunState, manual: ManualDefinition) -> void:
	run.hand_levels.level_up(manual.hand.id)


## Refuse un heritage deja possede. S'il etait propose en boutique, l'offre disparait.
static func give_legacy(run: RunState, legacy: LegacyDefinition) -> bool:
	for owned: LegacyDefinition in run.legacies:
		if owned.id == legacy.id:
			return false
	run.legacies.append(legacy)
	if run.legacy_offer != null and run.legacy_offer.id == legacy.id:
		run.legacy_offer = null
	return true


## Ouvre un sceau-tresor sans le payer. Refuse si un sceau est deja ouvert.
static func open_pack(shop: ShopState, pack: PackDefinition) -> bool:
	if shop == null or shop.opening != null:
		return false
	shop.open_pack(pack)
	return true


## Gagne le goulot en cours : recompense et boutique suivent comme apres un vrai coup.
static func win_round(run: RunState) -> bool:
	return run.status == RunState.Status.IN_ROUND and run.current_round.win_now()


## Saute au royaume et au goulot donnes (numeros affiches, a partir de 1) et relance le round.
## Hors des royaumes connus, ou run terminee : refuse et rien ne change.
static func jump_to(run: RunState, realm_number: int, bottleneck_number: int) -> bool:
	if run.status == RunState.Status.WON or run.status == RunState.Status.LOST:
		return false
	if not run.progress.restore({"realm": realm_number - 1, "bottleneck": bottleneck_number - 1}):
		return false
	run.start()
	return true
