extends Control
## Page des statistiques du profil.

signal back_requested

## Injecte par main avant l'ajout a l'arbre. Par defaut un profil vide (scene lancee seule, tests).
var profile: ProfileStats = ProfileStats.new()


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	_add_row("UI_STATS_RUNS", str(profile.runs_started))
	_add_row("UI_STATS_WINS", str(profile.runs_won))
	_add_row("UI_STATS_WIN_RATE", "%d %%" % _win_rate())
	_add_row("UI_STATS_BEST_REALM", _realm_name(profile.best_realm))
	_add_row("UI_STATS_BEST_HAND_SCORE", str(profile.best_hand_score))
	_add_row("UI_STATS_HANDS_PLAYED", str(profile.hands.total()))
	_add_row("UI_STATS_FAVORITE_HAND", _favorite_hand())


func _add_row(name_key: String, value: String) -> void:
	var name_label := Label.new()
	name_label.text = tr(name_key)
	var value_label := Label.new()
	value_label.text = value
	%Grid.add_child(name_label)
	%Grid.add_child(value_label)


func _win_rate() -> int:
	if profile.runs_started == 0:
		return 0
	return roundi(100.0 * profile.runs_won / profile.runs_started)


## Le profil stocke l'ordre du royaume, pas son nom : on le retrouve dans le catalogue.
func _realm_name(order: int) -> String:
	for realm: RealmDefinition in RealmCatalog.load_definitions():
		if realm.order == order:
			return tr(realm.name_key)
	return tr("UI_NONE")


func _favorite_hand() -> String:
	var id: String = profile.hands.most_played()
	if id.is_empty():
		return tr("UI_NONE")
	for hand: HandDefinition in HandCatalog.load_definitions():
		if hand.id == id:
			return tr("UI_STATS_HAND_COUNT") % [tr(hand.name_key), profile.hands.count_of(id)]
	return id