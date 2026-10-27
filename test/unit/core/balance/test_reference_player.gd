extends GutTest
## Joueur de reference : deterministe, trouve la meilleure main, voit le gain d'un artefact et d'un niveau.

var _content: GameContent
var _player: ReferencePlayer


func before_all() -> void:
	_content = GameContent.load_default()
	_player = ReferencePlayer.new(_content.starter_deck, _content.round_rules, _content.hands)


func _card(uid: int, element: Element.Type, rank: int) -> CardInstance:
	return CardInstance.new(uid, CardData.create(StringName("c%d" % uid), element, rank))


func _total_gain(base: PackedFloat32Array, other: PackedFloat32Array) -> float:
	var total := 0.0
	for i: int in base.size():
		total += other[i] - base[i]
	return total


func test_meme_graine_memes_scores() -> void:
	assert_eq(_player.round_scores(5, 42), _player.round_scores(5, 42))
	assert_ne(_player.round_scores(5, 42), _player.round_scores(5, 43))


func test_trouve_la_meilleure_main() -> void:
	var hand: Array[CardInstance] = []
	for rank: int in [1, 3, 5, 7, 9]:
		hand.append(_card(rank, Element.Type.FEU, rank))
	hand.append(_card(20, Element.Type.EAU, 2))
	hand.append(_card(21, Element.Type.BOIS, 4))
	hand.append(_card(22, Element.Type.METAL, 6))
	var best := _player.best_play(hand)
	assert_eq(best.hand.definition.id, "main_purete", "cinq feux : la purete bat le reste")
	assert_eq(_player.last_played.size(), 5)


func test_un_artefact_de_qi_augmente_le_score() -> void:
	var sword: ArtifactDefinition = load("res://content/artifacts/artefact_epee_volante.tres")
	var artifacts: Array[ArtifactDefinition] = [sword]
	assert_gt(_total_gain(_player.round_scores(10, 7), _player.round_scores(10, 7, artifacts)), 0.0)


func test_un_niveau_de_main_compte() -> void:
	var levels := HandLevels.new()
	for i: int in 5:
		levels.level_up("main_double_paire")
	assert_gt(_total_gain(_player.round_scores(10, 7), _player.round_scores(10, 7, [], levels)), 0.0)
