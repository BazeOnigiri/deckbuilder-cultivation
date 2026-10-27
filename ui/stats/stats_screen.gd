extends Control
## Page des statistiques du profil, sur un rouleau : une ligne « nom ..... valeur » par statistique.

signal back_requested

## Injecte par main avant l'ajout a l'arbre. Par defaut un profil vide (scene lancee seule, tests).
var profile: ProfileStats = ProfileStats.new()
## Injecte par main avant l'ajout a l'arbre. Vide : contenu charge par defaut.
var content: GameContent


func _ready() -> void:
	if content == null:
		content = GameContent.load_default()
	%BackButton.pressed.connect(back_requested.emit)
	%Scroll.unroll(get_theme_constant(&"unroll_ms", &"ScrollPanel") / 1000.0)
	_add_row("UI_STATS_RUNS", str(profile.runs_started))
	_add_row("UI_STATS_WINS", str(profile.runs_won))
	_add_row("UI_STATS_WIN_RATE", "%d %%" % _win_rate())
	_add_row("UI_STATS_BEST_REALM", _realm_name(profile.best_realm))
	_add_row("UI_STATS_BEST_HAND_SCORE", str(profile.best_hand_score))
	_add_row("UI_STATS_HANDS_PLAYED", str(profile.hands.total()))
	_add_row("UI_STATS_FAVORITE_HAND", _favorite_hand())


func _add_row(name_key: String, value: String) -> void:
	%Grid.add_child(ScrollRows.row(name_key, value))


func _win_rate() -> int:
	if profile.runs_started == 0:
		return 0
	return roundi(100.0 * profile.runs_won / profile.runs_started)


## Le profil stocke l'ordre du royaume, pas son nom : on le retrouve dans le catalogue.
func _realm_name(order: int) -> String:
	for realm: RealmDefinition in content.realms:
		if realm.order == order:
			return tr(realm.name_key)
	return tr("UI_NONE")


func _favorite_hand() -> String:
	var id: String = profile.hands.most_played()
	if id.is_empty():
		return tr("UI_NONE")
	for hand: HandDefinition in content.hands:
		if hand.id == id:
			return tr("UI_STATS_HAND_COUNT") % [tr(hand.name_key), profile.hands.count_of(id)]
	return id