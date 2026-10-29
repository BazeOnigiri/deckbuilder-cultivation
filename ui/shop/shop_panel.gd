class_name ShopPanel
extends VBoxContainer
## Boutique affichee entre deux goulots, dans un pavillon laque : enseigne 坊市 entre deux lanternes,
## offres posees sur des etoffes avec leur etiquette de prix. Construite en code : pas de .tscn.
## A l'ouverture les offres se retournent ; un achat file vers la rangee haute ; un manuel montre le gain de niveau.
## Un sceau-tresor achete s'ouvre dans un rouleau : on clique un choix pour le garder ; fermer le rouleau le passe.

signal changed

## Enseigne du marche, decorative : identique dans toutes les langues.
const SIGN_GLYPHS := "坊市"
const LANTERN := preload("res://ui/shop/lanterne.svg")

var feel: ShopFeel = preload("res://ui/shop/shop_feel.tres")
var settings: GameSettings = GameSettings.new()
## (kind: ItemSlot.Kind) -> Vector2 : emplacement libre de la rangee haute ou file un achat. Vide : pas d'envol.
var fly_target: Callable
## Niveaux des mains de la run, pour le message apres un manuel. Pose par round_screen.
var levels: HandLevels = HandLevels.new()

var _shop: ShopState
var _title := Label.new()
var _offers := HBoxContainer.new()
var _level_up := SideColumn.make_label(&"SideCaption")
var _reroll := Button.new()
## Rouleau du sceau ouvert, null si aucun.
var _pack_scroll: ScrollOverlay


func _ready() -> void:
	var pavilion := ShopPavilion.new()
	pavilion.size_flags_horizontal = SIZE_SHRINK_CENTER
	add_child(pavilion)
	var layout := VBoxContainer.new()
	pavilion.add_child(layout)
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(_lantern(1.0))
	var sign := VBoxContainer.new()
	var glyphs := SideColumn.make_label(&"ShopSign")
	glyphs.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	glyphs.text = SIGN_GLYPHS
	glyphs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.add_child(glyphs)
	_title.theme_type_variation = &"SideCaption"
	_title.text = "UI_SHOP"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.add_child(_title)
	header.add_child(sign)
	header.add_child(_lantern(-1.0))
	layout.add_child(header)
	# Une seule rangee : jusqu'a six etoffes (heritage Etal comprise) tiennent en 1152 px de large, le sceau
	# Relancer passe dessous. Une seconde rangee d'offres ferait deborder la boutique en hauteur.
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_offers)
	layout.add_child(row)
	_reroll.theme_type_variation = &"SealButton"
	_reroll.icon = get_theme_icon(&"icon", &"StoneIcon")
	_reroll.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_reroll.size_flags_horizontal = SIZE_SHRINK_CENTER
	layout.add_child(_reroll)
	_level_up.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Retour a la ligne : le message prend la largeur des offres au lieu d'elargir la boutique.
	_level_up.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_level_up)
	_reroll.pressed.connect(_on_reroll_pressed)


## side : 1 ou -1, les deux lanternes partent en sens oppose.
func _lantern(side: float) -> TextureRect:
	var lantern := TextureRect.new()
	lantern.texture = LANTERN
	var height: float = get_theme_constant(&"lantern_height", &"ShopPavilion")
	lantern.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lantern.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	lantern.custom_minimum_size = Vector2(height * LANTERN.get_width() / LANTERN.get_height(), height)
	lantern.size_flags_vertical = SIZE_SHRINK_BEGIN
	# Accrochee par le haut du cordon.
	lantern.pivot_offset = Vector2(lantern.custom_minimum_size.x / 2.0, 0.0)
	if not settings.reduce_motion and feel.lantern_time > 0.0:
		lantern.rotation = -feel.lantern_swing * side
		var tween := lantern.create_tween().set_loops()
		tween.tween_property(lantern, "rotation", feel.lantern_swing * side, feel.lantern_time).set_trans(Tween.TRANS_SINE)
		tween.tween_property(lantern, "rotation", -feel.lantern_swing * side, feel.lantern_time).set_trans(Tween.TRANS_SINE)
	return lantern


func open(shop: ShopState) -> void:
	_shop = shop
	_level_up.text = ""
	_level_up.hide()
	show()
	_refresh()
	_reveal()
	# Sauvegarde reprise avec un sceau ouvert : le rouleau revient avec les memes choix.
	if _shop.opening != null:
		_show_opening()


## Redessine les offres si la boutique est ouverte (pierres changees hors de la boutique, par une vente).
func refresh() -> void:
	if visible and _shop != null:
		_refresh()


func _refresh() -> void:
	# Achat au clavier ou a la manette : le focus reste a la meme place dans la rangee refaite.
	var focused := -1
	var owner := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	for i: int in _offers.get_child_count():
		if owner != null and _offers.get_child(i).is_ancestor_of(owner):
			focused = i
	for child: Node in _offers.get_children():
		_offers.remove_child(child)
		child.queue_free()
	for i: int in _shop.offers.size():
		var artifact: ArtifactDefinition = _shop.offers[i]
		_add_offer(ItemSlot.Kind.ARTIFACT, artifact.glyph, artifact.name_key, tr(artifact.description_key),
			artifact.price, _shop.can_buy(i), _on_buy_pressed.bind(i), artifact.icon, null, artifact.rarity)
	for i: int in _shop.manual_offers.size():
		var manual: ManualDefinition = _shop.manual_offers[i]
		var hand: HandDefinition = manual.hand
		_add_offer(ItemSlot.Kind.MANUAL, manual.glyph, hand.name_key,
			tr("UI_MANUAL_DESC") % [tr(hand.name_key), hand.level_qi, hand.level_comprehension],
			manual.price, _shop.can_buy_manual(i), _on_buy_manual_pressed.bind(i), null, manual)
	for i: int in _shop.pill_offers.size():
		var pill: PillDefinition = _shop.pill_offers[i]
		_add_offer(ItemSlot.Kind.PILL, pill.glyph, pill.name_key, tr(pill.description_key),
			pill.price, _shop.can_buy_pill(i), _on_buy_pill_pressed.bind(i))
	for i: int in _shop.pack_offers.size():
		var pack: PackDefinition = _shop.pack_offers[i]
		_add_offer(ItemSlot.Kind.PACK, pack.glyph, pack.name_key, tr(pack.description_key),
			pack.price, _shop.can_buy_pack(i), _on_buy_pack_pressed.bind(i))
	var legacy := _shop.legacy_offer()
	if legacy != null:
		_add_offer(ItemSlot.Kind.LEGACY, legacy.glyph, legacy.name_key, tr(legacy.description_key),
			legacy.price, _shop.can_buy_legacy(), _on_buy_legacy_pressed)
	_reroll.text = tr("UI_SHOP_REROLL") % _shop.reroll_cost
	_reroll.disabled = not _shop.can_reroll()
	if focused >= 0:
		var place := mini(focused, _offers.get_child_count() - 1)
		if place < 0 or not Focus.grab_first(_offers.get_child(place)):
			Focus.grab_first(self)


## buy(slot) : achete l'offre ; le slot sert de point de depart a l'envol.
func _add_offer(kind: ItemSlot.Kind, glyph: String, name_key: String, description: String, price: int,
		can_buy: bool, buy: Callable, icon: Texture2D = null, manual: ManualDefinition = null, rarity: int = -1) -> void:
	var cloth := PanelContainer.new()
	cloth.theme_type_variation = &"ShopCloth"
	var offer := VBoxContainer.new()
	cloth.add_child(offer)
	var slot := ItemSlot.new()
	slot.kind = kind
	slot.glyph = glyph
	slot.picture = icon
	slot.rarity = rarity
	if manual != null:
		slot.cover_tier = manual.tier
		slot.cover_pattern = manual.pattern
	slot.set_info(tr(name_key), description)
	slot.disabled = not can_buy
	slot.size_flags_horizontal = SIZE_SHRINK_CENTER
	slot.pressed.connect(func() -> void: buy.call(slot))
	offer.add_child(slot)
	var title := SideColumn.make_label(&"SideCaption", name_key)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Largeur fixe et retour a la ligne : un nom long ne pousse pas la boutique hors de l'ecran.
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = get_theme_constant(&"title_width", &"ShopCloth")
	offer.add_child(title)
	var tag := PanelContainer.new()
	tag.theme_type_variation = &"PriceTag"
	tag.size_flags_horizontal = SIZE_SHRINK_CENTER
	var cost := HBoxContainer.new()
	cost.alignment = BoxContainer.ALIGNMENT_CENTER
	var amount := SideColumn.make_label(&"Price")
	amount.text = str(price)
	cost.add_child(amount)
	cost.add_child(StoneIcon.new())
	tag.add_child(cost)
	offer.add_child(tag)
	_offers.add_child(cloth)


## Les offres se retournent l'une apres l'autre, comme des cartes posees face cachee.
func _reveal() -> void:
	if settings.reduce_motion or feel.flip_time <= 0.0:
		return
	var offers := _offers.get_children()
	for i: int in offers.size():
		var offer := offers[i] as Control
		# Taille connue a la frame suivante seulement : pivot pose au debut du tween.
		offer.scale = Vector2(0.0, 1.0)
		var tween := offer.create_tween()
		tween.tween_interval(i * feel.flip_stagger)
		tween.tween_callback(func() -> void: offer.pivot_offset = offer.size / 2)
		tween.tween_property(offer, "scale:x", 1.0, feel.flip_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Le glyphe achete quitte la boutique et file vers son emplacement de la rangee haute.
func _fly(slot: ItemSlot) -> void:
	if settings.reduce_motion or not fly_target.is_valid() or feel.fly_time <= 0.0:
		return
	var target: Vector2 = fly_target.call(slot.kind)
	if not target.is_finite():
		return
	var ghost := ItemSlot.new()
	ghost.kind = slot.kind
	ghost.glyph = slot.glyph
	ghost.picture = slot.picture
	ghost.mouse_filter = MOUSE_FILTER_IGNORE
	# Hors de la mise en page de la boutique : il se deplace librement.
	ghost.top_level = true
	add_child(ghost)
	ghost.global_position = slot.get_global_rect().position
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "global_position", target - slot.size / 2, feel.fly_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(ghost.queue_free)


func _show_level_up(hand: HandDefinition) -> void:
	var level := levels.level_of(hand.id)
	_level_up.show()
	_level_up.text = tr("UI_SHOP_LEVEL_UP") % [tr(hand.name_key), level, hand.qi_at(level - 1),
		hand.comprehension_at(level - 1), hand.qi_at(level), hand.comprehension_at(level)]
	if settings.reduce_motion or feel.level_up_fade <= 0.0:
		return
	_level_up.modulate.a = 0.0
	_level_up.create_tween().tween_property(_level_up, "modulate:a", 1.0, feel.level_up_fade)


func _on_buy_pressed(slot: ItemSlot, index: int) -> void:
	# Envol lance avant l'achat : apres, l'emplacement libre vise est deja pris.
	if _shop.can_buy(index):
		_fly(slot)
	if _shop.buy(index):
		Sons.play(&"achat")
		changed.emit()
		_refresh()


func _on_reroll_pressed() -> void:
	if _shop.reroll():
		changed.emit()
		_refresh()
		_reveal()


func _on_buy_manual_pressed(_slot: ItemSlot, index: int) -> void:
	var hand: HandDefinition = _shop.manual_offers[index].hand
	if _shop.buy_manual(index):
		Sons.play(&"manuel")
		changed.emit()
		_refresh()
		_show_level_up(hand)


func _on_buy_pill_pressed(slot: ItemSlot, index: int) -> void:
	# Comme pour un artefact : envol avant l'achat.
	if _shop.can_buy_pill(index):
		_fly(slot)
	if _shop.buy_pill(index):
		Sons.play(&"achat")
		changed.emit()
		_refresh()


func _on_buy_pack_pressed(_slot: ItemSlot, index: int) -> void:
	if _shop.buy_pack(index):
		Sons.play(&"sceau")
		changed.emit()
		_refresh()
		_show_opening()


## Rouleau du sceau ouvert : ses choix, combien il reste a prendre, et le sceau Passer.
func _show_opening(animated: bool = true) -> void:
	var opening := _shop.opening
	var body := VBoxContainer.new()
	var picks := SideColumn.make_label(&"ScrollText")
	picks.text = tr("UI_PACK_PICKS") % opening.picks_left
	picks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(picks)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i: int in opening.choices.size():
		var choice := _choice(opening.pack.kind, opening.choices[i])
		choice.disabled = not _shop.can_take(i)
		choice.pressed.connect(_on_take_pressed.bind(i))
		row.add_child(choice)
	body.add_child(row)
	var skip := Button.new()
	skip.theme_type_variation = &"SealButton"
	skip.text = "UI_PACK_SKIP"
	skip.size_flags_horizontal = SIZE_SHRINK_CENTER
	body.add_child(skip)
	# Pose sur la fenetre : la boutique est rangee dans un conteneur qui placerait le voile comme un enfant.
	_pack_scroll = ScrollOverlay.open(get_viewport(), tr(opening.pack.name_key), body, animated and not settings.reduce_motion)
	_pack_scroll.hide_close()
	skip.pressed.connect(_pack_scroll.close)
	# Fermer le rouleau (Passer, Echap ou clic a cote) laisse le reste du sceau.
	_pack_scroll.closed.connect(_on_pack_closed)


## Un choix de sceau, cliquable : emplacement d'objet, ou carte dans un cadre.
func _choice(kind: PackDefinition.Kind, item: Resource) -> BaseButton:
	if kind == PackDefinition.Kind.CARD:
		var card := CardInstance.new(-1, item as CardData, _shop.card_ranks())
		var frame := Button.new()
		frame.flat = true
		frame.tooltip_text = CardView.tip_text(card)
		FocusTip.attach(frame)
		var small := CardView.small(card, feel.pack_card_scale)
		frame.custom_minimum_size = small.custom_minimum_size
		frame.add_child(small)
		return frame
	var slot := ItemSlot.new()
	match kind:
		PackDefinition.Kind.ARTIFACT:
			var artifact := item as ArtifactDefinition
			slot.glyph = artifact.glyph
			slot.picture = artifact.icon
			slot.rarity = artifact.rarity
			slot.set_info(tr(artifact.name_key), tr(artifact.description_key))
		PackDefinition.Kind.MANUAL:
			var manual := item as ManualDefinition
			slot.kind = ItemSlot.Kind.MANUAL
			slot.glyph = manual.glyph
			slot.cover_tier = manual.tier
			slot.cover_pattern = manual.pattern
			slot.set_info(tr(manual.hand.name_key), tr("UI_MANUAL_DESC") % [tr(manual.hand.name_key),
				manual.hand.level_qi, manual.hand.level_comprehension])
		PackDefinition.Kind.PILL:
			var pill := item as PillDefinition
			slot.kind = ItemSlot.Kind.PILL
			slot.glyph = pill.glyph
			slot.set_info(tr(pill.name_key), tr(pill.description_key))
	slot.size_flags_vertical = SIZE_SHRINK_CENTER
	return slot


func _on_take_pressed(index: int) -> void:
	var kind := _shop.opening.pack.kind
	var manual: ManualDefinition = _shop.opening.choices[index] if kind == PackDefinition.Kind.MANUAL else null
	if not _shop.take(index):
		return
	Sons.play(&"manuel" if manual != null else &"achat")
	changed.emit()
	if manual != null:
		_show_level_up(manual.hand)
	# Encore des choix : le rouleau est redessine sur place, sans se derouler a nouveau.
	var scroll := _pack_scroll
	_pack_scroll = null
	scroll.closed.disconnect(_on_pack_closed)
	scroll.close()
	if _shop.opening != null:
		_show_opening(false)
	_refresh()


func _on_pack_closed() -> void:
	_pack_scroll = null
	if _shop.opening != null:
		_shop.skip()
		changed.emit()
		_refresh()


func _on_buy_legacy_pressed(_slot: ItemSlot) -> void:
	if _shop.buy_legacy():
		Sons.play(&"achat")
		changed.emit()
		_refresh()
