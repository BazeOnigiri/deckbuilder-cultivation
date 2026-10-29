extends Control
## Page des statistiques du profil, sur un rouleau : tuiles des grands chiffres, meilleur royaume en calligraphie,
## barres d'encre des mains les plus jouees et des artefacts les plus achetes, reussite des tribulations.
## Un sceau ouvre l'historique des parties.

signal back_requested

## Nombre de mains montrees en barres.
const TOP_HANDS := 5
## Nombre d'artefacts montres en barres.
const TOP_ARTIFACTS := 5
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
	%BackButton.grab_focus(not Focus.shown)
	%HistoryButton.pressed.connect(_show_history)
	%AchievementsButton.pressed.connect(_show_achievements)
	%Body.custom_minimum_size.y = get_theme_constant(&"tab_height", &"ScrollPanel")
	%Scroll.unroll(0.0 if settings.reduce_motion else get_theme_constant(&"unroll_ms", &"ScrollPanel") / 1000.0)
	%Grid.add_child(ScrollTiles.stat(str(profile.runs_started), "UI_STATS_RUNS"))
	%Grid.add_child(ScrollTiles.stat(str(profile.runs_won), "UI_STATS_WINS", WIN_GLYPH))
	%Grid.add_child(ScrollTiles.stat(tr("UI_STATS_PERCENT") % _win_rate(), "UI_STATS_WIN_RATE"))
	%Grid.add_child(ScrollTiles.stat(str(profile.best_hand_score), "UI_STATS_BEST_HAND_SCORE"))
	%BestRealm.text = _realm_name(profile.best_realm)
	_add_bars()
	_add_purchases()
	_add_tribulations()


## Manette : B (ui_cancel) revient au menu comme le sceau Retour.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()


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


func _show_achievements() -> void:
	ScrollOverlay.open(self, "UI_ACHIEVEMENTS_TITLE", AchievementsList.build(profile, content), not settings.reduce_motion)


func _show_history() -> void:
	ScrollOverlay.open(self, "UI_HISTORY_TITLE", GameHistory.build(profile, content), not settings.reduce_motion)


## Les artefacts les plus achetes en boutique, comme les mains. Un artefact retire du jeu est ignore.
func _add_purchases() -> void:
	var bought: Array[ArtifactDefinition] = []
	for id: String in profile.top_purchases(profile.artifact_purchases.size()):
		var artifact := content.artifact_by_id(StringName(id))
		if artifact != null:
			bought.append(artifact)
	if bought.is_empty():
		%Purchases.add_child(SideColumn.make_label(&"ScrollCaption", "UI_NONE"))
		return
	var most: int = profile.purchases_of(bought[0].id)
	for artifact: ArtifactDefinition in bought.slice(0, TOP_ARTIFACTS):
		%Purchases.add_child(ScrollTiles.bar(tr(artifact.name_key), profile.purchases_of(artifact.id), most))


## Taux de reussite de chaque tribulation affrontee au moins une fois : « 67 % (2/3) ».
func _add_tribulations() -> void:
	var any := false
	for tribulation: Resource in Compendium.new(content, profile).entries(Compendium.Kind.TRIBULATION):
		var won := profile.tribulation_wins(tribulation.id)
		var tried := won + profile.tribulation_losses(tribulation.id)
		if tried == 0:
			continue
		any = true
		%Tribulations.add_child(ScrollRows.row(tribulation.name_key, tr("UI_STATS_TRIBULATION_RATE") % [roundi(100.0 * won / tried), won, tried]))
	if not any:
		%Tribulations.add_child(SideColumn.make_label(&"ScrollCaption", "UI_NONE"))
