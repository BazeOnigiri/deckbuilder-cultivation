extends Control
## Page des statistiques du profil, sur un rouleau : tuiles des grands chiffres, meilleur royaume en calligraphie,
## barres d'encre des mains les plus jouees.

signal back_requested

## Nombre de mains montrees en barres.
const TOP_HANDS := 5
const WIN_GLYPH := "破"

## Injecte par main avant l'ajout a l'arbre. Par defaut un profil vide (scene lancee seule, tests).
var profile: ProfileStats = ProfileStats.new()
## Injecte par main avant l'ajout a l'arbre.
var settings: GameSettings = GameSettings.new()
## Injecte par main avant l'ajout a l'arbre. Vide : contenu charge par defaut.
var content: GameContent


func _ready() -> void:
	if content == null:
		content = GameContent.load_default()
	%BackButton.pressed.connect(back_requested.emit)
	%Scroll.unroll(0.0 if settings.reduce_motion else get_theme_constant(&"unroll_ms", &"ScrollPanel") / 1000.0)
	%Grid.add_child(ScrollTiles.stat(str(profile.runs_started), "UI_STATS_RUNS"))
	%Grid.add_child(ScrollTiles.stat(str(profile.runs_won), "UI_STATS_WINS", WIN_GLYPH))
	%Grid.add_child(ScrollTiles.stat(tr("UI_STATS_PERCENT") % _win_rate(), "UI_STATS_WIN_RATE"))
	%Grid.add_child(ScrollTiles.stat(str(profile.best_hand_score), "UI_STATS_BEST_HAND_SCORE"))
	%BestRealm.text = _realm_name(profile.best_realm)
	_add_bars()


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


## Les mains les plus jouees, la plus jouee en barre pleine. Aucune main jouee : une ligne « aucune ».
func _add_bars() -> void:
	var played: Array[HandDefinition] = content.hands.filter(
		func(hand: HandDefinition) -> bool: return profile.hands.count_of(hand.id) > 0)
	played.sort_custom(func(a: HandDefinition, b: HandDefinition) -> bool:
		return profile.hands.count_of(a.id) > profile.hands.count_of(b.id))
	if played.is_empty():
		%Bars.add_child(SideColumn.make_label(&"ScrollCaption", "UI_NONE"))
		return
	var most: int = profile.hands.count_of(played[0].id)
	for hand: HandDefinition in played.slice(0, TOP_HANDS):
		%Bars.add_child(ScrollTiles.bar(tr(hand.name_key), profile.hands.count_of(hand.id), most))
