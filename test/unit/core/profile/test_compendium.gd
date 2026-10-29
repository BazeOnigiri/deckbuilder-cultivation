extends GutTest
## Compendium : tout le contenu par categorie, vus / total, et les tribulations tirees des royaumes.

var _content: GameContent
var _profile: ProfileStats
var _compendium: Compendium


func before_all() -> void:
	_content = GameContent.load_default()


func before_each() -> void:
	_profile = ProfileStats.new()
	_compendium = Compendium.new(_content, _profile)


func test_totaux_issus_des_catalogues() -> void:
	assert_eq(_compendium.total(Compendium.Kind.ARTIFACT), _content.artifacts.size())
	assert_eq(_compendium.total(Compendium.Kind.PILL), _content.pills.size())
	assert_eq(_compendium.total(Compendium.Kind.MANUAL), _content.manuals.size())
	assert_eq(_compendium.total(Compendium.Kind.LEGACY), _content.legacies.size())
	assert_eq(_compendium.total(Compendium.Kind.PACK), _content.packs.size())
	assert_gt(_compendium.total(Compendium.Kind.TRIBULATION), 0)


func test_tribulations_sont_les_goulots_a_contrainte_sans_doublon() -> void:
	var ids: Dictionary = {}
	for tribulation: Resource in _compendium.entries(Compendium.Kind.TRIBULATION):
		assert_not_null(tribulation.constraint)
		assert_false(ids.has(tribulation.id), "une seule fois")
		ids[tribulation.id] = true


func test_rien_de_vu_au_depart() -> void:
	for kind: int in Compendium.Kind.values():
		assert_eq(_compendium.seen_count(kind as Compendium.Kind), 0)


func test_compte_les_vus() -> void:
	var artifact := _content.artifacts[0]
	_profile.mark_seen(Compendium.KEYS[Compendium.Kind.ARTIFACT], artifact.id)
	assert_eq(_compendium.seen_count(Compendium.Kind.ARTIFACT), 1)
	assert_true(_compendium.is_seen(Compendium.Kind.ARTIFACT, artifact))
	assert_false(_compendium.is_seen(Compendium.Kind.ARTIFACT, _content.artifacts[1]))
	assert_eq(_compendium.seen_count(Compendium.Kind.PILL), 0, "par categorie")


func test_contenu_retire_du_jeu_ne_compte_plus() -> void:
	_profile.mark_seen(Compendium.KEYS[Compendium.Kind.ARTIFACT], &"artefact_disparu")
	assert_eq(_compendium.seen_count(Compendium.Kind.ARTIFACT), 0)


func test_categorie_d_un_contenu() -> void:
	assert_eq(Compendium.kind_of(_content.artifacts[0]), Compendium.Kind.ARTIFACT)
	assert_eq(Compendium.kind_of(_content.packs[0]), Compendium.Kind.PACK)
	assert_eq(Compendium.kind_of(_content.hands[0]), -1)
	var plain := BottleneckDefinition.new()
	assert_eq(Compendium.kind_of(plain), -1, "sans contrainte, ce n'est pas une tribulation")
