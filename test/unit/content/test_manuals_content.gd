extends GutTest

const MANUALS_DIR := "res://content/manuals"

var _manuals: Array[ManualDefinition]


func before_all() -> void:
	_manuals = ManualCatalog.load_definitions(MANUALS_DIR)


func test_tous_les_manuels_valides() -> void:
	assert_gt(_manuals.size(), 0)
	for manual: ManualDefinition in _manuals:
		assert_true(manual.is_valid(), "manuel invalide : %s" % manual.resource_path)


## Si une main est ajoutee sans relancer tools/generate_manuals.gd, ce test le signale.
func test_un_manuel_par_main() -> void:
	var hand_ids: Array[String] = []
	for manual: ManualDefinition in _manuals:
		assert_false(hand_ids.has(manual.hand.id), "deux manuels pour %s" % manual.hand.id)
		hand_ids.append(manual.hand.id)
	for hand: HandDefinition in HandCatalog.load_definitions():
		assert_true(hand_ids.has(hand.id), "pas de manuel pour %s" % hand.id)


func test_ids_uniques() -> void:
	var ids: Dictionary = {}
	for manual: ManualDefinition in _manuals:
		assert_false(ids.has(manual.id), "id en double : %s" % manual.id)
		ids[manual.id] = true