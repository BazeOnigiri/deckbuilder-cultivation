extends GutTest

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return rng


func test_tout_le_contenu_est_charge() -> void:
	assert_not_null(_content.starter_deck)
	assert_not_null(_content.round_rules)
	assert_not_null(_content.economy)
	assert_not_null(_content.shop_rules)
	assert_gt(_content.hands.size(), 0)
	assert_gt(_content.realms.size(), 0)
	assert_gt(_content.artifacts.size(), 0)
	assert_gt(_content.manuals.size(), 0)
	assert_gt(_content.pills.size(), 0)


func test_nouvelle_run_jouable() -> void:
	var run := _content.new_run(_rng())
	run.start()
	assert_eq(run.current_round.hand().size(), _content.round_rules.hand_size)


func test_nouvelle_boutique_remplie() -> void:
	var rng := _rng()
	var shop := _content.new_shop(_content.new_run(rng), rng)
	assert_eq(shop.offers.size() + shop.manual_offers.size() + shop.pill_offers.size(), _content.shop_rules.offer_count)

func test_sceaux_valides_et_dessinables() -> void:
	var font: FontFile = load("res://ui/fonts/MaShanZheng-Sceaux.ttf")
	assert_eq(_content.packs.size(), PackDefinition.Kind.size(), "un sceau par famille")
	for pack: PackDefinition in _content.packs:
		assert_true(pack.is_valid(), String(pack.id))
		assert_eq(pack.glyph.length(), 1, String(pack.id))
		assert_true(font.has_char(pack.glyph.unicode_at(0)), "glyphe absent de la police : %s" % pack.id)
