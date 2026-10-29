extends Control
## Compendium sur un rouleau : tout le contenu du jeu par onglets. Ce que le joueur n'a jamais vu (offert en
## boutique ou possede) reste une silhouette ; chaque onglet compte « vus x / total ».

signal back_requested

## Injecte par main avant l'ajout a l'arbre. Par defaut un profil vide (scene lancee seule, tests).
var profile: ProfileStats = ProfileStats.new()
## Injecte par main avant l'ajout a l'arbre.
var settings: GameSettings = GameSettings.new()
## Injecte par main avant l'ajout a l'arbre. Vide : contenu charge par defaut.
var content: GameContent

## Titre de l'onglet de chaque categorie, dans l'ordre de Compendium.Kind.
const TAB_KEYS: Array[String] = ["UI_COMPENDIUM_ARTIFACTS", "UI_COMPENDIUM_PILLS", "UI_COMPENDIUM_MANUALS",
	"UI_COMPENDIUM_LEGACIES", "UI_COMPENDIUM_PACKS", "UI_COMPENDIUM_TRIBULATIONS"]


func _ready() -> void:
	if content == null:
		content = GameContent.load_default()
	%BackButton.pressed.connect(back_requested.emit)
	%Scroll.unroll(0.0 if settings.reduce_motion else get_theme_constant(&"unroll_ms", &"ScrollPanel") / 1000.0)
	var compendium := Compendium.new(content, profile)
	for kind: int in Compendium.Kind.values():
		_add_tab(compendium, kind as Compendium.Kind)


func _add_tab(compendium: Compendium, kind: Compendium.Kind) -> void:
	var page := VBoxContainer.new()
	var counter := SideColumn.make_label(&"ScrollCaption")
	counter.text = tr("UI_COMPENDIUM_SEEN") % [compendium.seen_count(kind), compendium.total(kind)]
	page.add_child(counter)
	var grid := HFlowContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item: Resource in compendium.entries(kind):
		var slot: ItemSlot = ContentSlots.of(item) if compendium.is_seen(kind, item) else ContentSlots.hidden(kind)
		grid.add_child(slot)
	page.add_child(grid)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(get_theme_constant(&"info_width", &"ScrollPanel"),
		get_theme_constant(&"tab_height", &"ScrollPanel"))
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)
	%Tabs.add_child(scroll)
	%Tabs.set_tab_title(%Tabs.get_tab_count() - 1, tr(TAB_KEYS[kind]))
