extends GutTest
## Tests de ElementCycle, de Element.to_id et de la donnée cycle_engendrement.tres.

const CYCLE_PATH: String = "res://content/cycles/cycle_engendrement.tres"

var _cycle: ElementCycle


func before_each() -> void:
	# CACHE_MODE_IGNORE : une copie neuve à chaque test, pour qu'un test
	# qui modifierait la ressource ne contamine pas les suivants.
	_cycle = ResourceLoader.load(CYCLE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as ElementCycle


# --- Donnée cycle_engendrement.tres ---

func test_ressource_chargee() -> void:
	assert_not_null(_cycle, "cycle_engendrement.tres doit exister et être un ElementCycle")


func test_cycle_engendrement_est_valide() -> void:
	assert_true(_cycle.is_valid())


func test_cycle_engendrement_suit_l_ordre_du_wuxing() -> void:
	var attendu: Array[Element.Type] = [
		Element.Type.BOIS,
		Element.Type.FEU,
		Element.Type.TERRE,
		Element.Type.METAL,
		Element.Type.EAU,
	]
	for i: int in attendu.size():
		var depuis: Element.Type = attendu[i]
		var vers: Element.Type = attendu[(i + 1) % attendu.size()]
		assert_eq(_cycle.next_of(depuis), vers,
			"%s doit engendrer %s" % [Element.to_id(depuis), Element.to_id(vers)])


# --- next_of et follows ---

func test_eau_engendre_bois_le_cycle_boucle() -> void:
	assert_eq(_cycle.next_of(Element.Type.EAU), Element.Type.BOIS)


func test_follows_dans_le_sens_du_cycle() -> void:
	assert_true(_cycle.follows(Element.Type.FEU, Element.Type.TERRE))


func test_follows_sens_inverse_est_faux() -> void:
	assert_false(_cycle.follows(Element.Type.TERRE, Element.Type.FEU))


func test_follows_element_identique_est_faux() -> void:
	assert_false(_cycle.follows(Element.Type.FEU, Element.Type.FEU))


func test_follows_element_absent_est_faux() -> void:
	var incomplet: ElementCycle = _creer_cycle([
		Element.Type.BOIS, Element.Type.FEU, Element.Type.TERRE, Element.Type.METAL,
	])
	assert_false(incomplet.follows(Element.Type.EAU, Element.Type.BOIS))


# --- is_valid sur des cycles construits ---

func test_cycle_avec_doublon_est_invalide() -> void:
	var cycle: ElementCycle = _creer_cycle([
		Element.Type.BOIS, Element.Type.FEU, Element.Type.TERRE, Element.Type.METAL, Element.Type.METAL,
	])
	assert_false(cycle.is_valid())


func test_cycle_incomplet_est_invalide() -> void:
	var cycle: ElementCycle = _creer_cycle([
		Element.Type.BOIS, Element.Type.FEU, Element.Type.TERRE, Element.Type.METAL,
	])
	assert_false(cycle.is_valid())


func test_cycle_vide_est_invalide() -> void:
	assert_false(ElementCycle.new().is_valid())


func test_cycle_dans_un_autre_ordre_est_valide() -> void:
	# Un cycle de destruction (bois > terre > eau > feu > métal) doit être accepté.
	var cycle: ElementCycle = _creer_cycle([
		Element.Type.BOIS, Element.Type.TERRE, Element.Type.EAU, Element.Type.FEU, Element.Type.METAL,
	])
	assert_true(cycle.is_valid())
	assert_eq(cycle.next_of(Element.Type.BOIS), Element.Type.TERRE)


# --- Element.to_id ---

func test_ids_des_elements_sont_distincts_et_non_vides() -> void:
	var ids: Dictionary = {}
	for value: int in Element.Type.values():
		var id: StringName = Element.to_id(value as Element.Type)
		assert_ne(id, &"", "l'élément %d doit avoir un ID" % value)
		ids[id] = true
	assert_eq(ids.size(), Element.Type.size(), "chaque élément doit avoir un ID unique")


# --- Utilitaires ---

func _creer_cycle(valeurs: Array) -> ElementCycle:
	var cycle: ElementCycle = ElementCycle.new()
	cycle.order.assign(valeurs)
	return cycle