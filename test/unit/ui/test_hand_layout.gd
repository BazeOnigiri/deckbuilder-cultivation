extends GutTest
## Eventail de la main et ressort des cartes : calculs purs.

const FEEL := preload("res://ui/cards/hand_feel.tres")
const CARD_WIDTH := 92.0


func test_main_vide() -> void:
	assert_eq(HandLayout.slots(0, 800, CARD_WIDTH, FEEL).size(), 0)


func test_une_carte_au_centre_et_droite() -> void:
	assert_eq(HandLayout.slots(1, 800, CARD_WIDTH, FEEL), [Vector3.ZERO] as Array[Vector3])


func test_eventail_symetrique() -> void:
	var slots := HandLayout.slots(8, 2000, CARD_WIDTH, FEEL)
	for i: int in slots.size():
		var mirror: Vector3 = slots[slots.size() - 1 - i]
		assert_almost_eq(slots[i].x, -mirror.x, 0.001, "x de la carte %d" % i)
		assert_almost_eq(slots[i].y, mirror.y, 0.001, "y de la carte %d" % i)
		assert_almost_eq(slots[i].z, -mirror.z, 0.001, "angle de la carte %d" % i)
	assert_almost_eq(slots[1].x - slots[0].x, CARD_WIDTH + FEEL.gap, 0.001, "espacement normal")
	assert_lt(slots[0].z, 0.0, "la carte de gauche penche a gauche")
	assert_almost_eq(slots[0].y, FEEL.arc_height, 0.001, "les bouts descendent")


func test_cartes_resserrees_si_trop_etroit() -> void:
	var width := 400.0
	var slots := HandLayout.slots(8, width, CARD_WIDTH, FEEL)
	assert_lte(slots[-1].x - slots[0].x + CARD_WIDTH, width + 0.001)


func test_ressort_atteint_sa_cible() -> void:
	var spring := CardSpring.new(Vector3.ZERO)
	var target := Vector3(100, -40, 0.2)
	for i: int in 120:
		spring.step(target, 1.0 / 60.0, FEEL.stiffness, FEEL.damping)
	assert_lt(spring.value.distance_to(target), 0.01)


func test_ressort_stable_avec_une_frame_tres_longue() -> void:
	var spring := CardSpring.new(Vector3.ZERO)
	spring.step(Vector3(100, 0, 0), 10.0, FEEL.stiffness, FEEL.damping)
	assert_true(spring.value.is_finite())
	assert_lt(spring.value.length(), 200.0)


func test_ressort_snap() -> void:
	var spring := CardSpring.new(Vector3.ZERO)
	spring.step(Vector3.ONE, 0.05, FEEL.stiffness, FEEL.damping)
	spring.snap(Vector3(5, 5, 5))
	assert_eq(spring.value, Vector3(5, 5, 5))
	assert_eq(spring.velocity, Vector3.ZERO)
