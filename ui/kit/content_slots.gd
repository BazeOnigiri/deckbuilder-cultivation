class_name ContentSlots
extends RefCounted
## Emplacements d'objets du contenu (artefact, pilule, manuel, sceau, heritage, tribulation) avec leur infobulle :
## nom, description et prix. Partages par le compendium, l'historique des parties et le bilan de fin de run.

## Sceau pose sur un objet jamais vu (police des sceaux).
const HIDDEN_GLYPH := "？"
const TRIBULATION_GLYPH := "劫"


## L'emplacement de ce contenu, ou null si ce n'est pas un contenu connu du compendium.
static func of(item: Resource) -> ItemSlot:
	var slot := ItemSlot.new()
	match Compendium.kind_of(item):
		Compendium.Kind.ARTIFACT:
			var artifact := item as ArtifactDefinition
			slot.glyph = artifact.glyph
			slot.picture = artifact.icon
			slot.rarity = artifact.rarity
			slot.set_info(_tr(artifact.name_key), _price(_tr(artifact.description_key), artifact.price))
		Compendium.Kind.PILL:
			var pill := item as PillDefinition
			slot.kind = ItemSlot.Kind.PILL
			slot.glyph = pill.glyph
			slot.set_info(_tr(pill.name_key), _price(_tr(pill.description_key), pill.price))
		Compendium.Kind.MANUAL:
			var manual := item as ManualDefinition
			slot.kind = ItemSlot.Kind.MANUAL
			slot.glyph = manual.glyph
			slot.cover_tier = manual.tier
			slot.cover_pattern = manual.pattern
			var hand := manual.hand
			slot.set_info(_tr(hand.name_key), _price(_tr("UI_MANUAL_DESC") % [_tr(hand.name_key), hand.level_qi,
				hand.level_comprehension], manual.price))
		Compendium.Kind.LEGACY:
			var legacy := item as LegacyDefinition
			slot.kind = ItemSlot.Kind.LEGACY
			slot.glyph = legacy.glyph
			slot.set_info(_tr(legacy.name_key), _price(_tr(legacy.description_key), legacy.price))
		Compendium.Kind.PACK:
			var pack := item as PackDefinition
			slot.kind = ItemSlot.Kind.PACK
			slot.glyph = pack.glyph
			slot.set_info(_tr(pack.name_key), _price(_tr(pack.description_key), pack.price))
		Compendium.Kind.TRIBULATION:
			var bottleneck := item as BottleneckDefinition
			slot.kind = ItemSlot.Kind.TRIBULATION
			slot.glyph = TRIBULATION_GLYPH
			slot.set_info(_tr(bottleneck.name_key), _tr(bottleneck.constraint.description_key))
		_:
			slot.free()
			return null
	return slot


## La silhouette d'un contenu jamais vu : un point d'interrogation en sceau, le nom cache dans l'infobulle.
static func hidden(kind: Compendium.Kind) -> ItemSlot:
	var slot := ItemSlot.new()
	slot.kind = {
		Compendium.Kind.PILL: ItemSlot.Kind.PILL,
		Compendium.Kind.MANUAL: ItemSlot.Kind.MANUAL,
		Compendium.Kind.LEGACY: ItemSlot.Kind.LEGACY,
		Compendium.Kind.PACK: ItemSlot.Kind.PACK,
		Compendium.Kind.TRIBULATION: ItemSlot.Kind.TRIBULATION,
	}.get(kind, ItemSlot.Kind.ARTIFACT)
	slot.glyph = HIDDEN_GLYPH
	slot.disabled = true
	slot.set_info(_tr("UI_COMPENDIUM_UNKNOWN"), "")
	return slot


static func _price(description: String, price: int) -> String:
	return description if price <= 0 else description + "\n" + _tr("UI_COMPENDIUM_PRICE") % price


static func _tr(key: String) -> String:
	return TranslationServer.translate(key)
