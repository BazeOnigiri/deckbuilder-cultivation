class_name ShopPanel
extends VBoxContainer
## Boutique affichee entre deux goulots, en emplacements comme la rangee haute. Construite en code : pas de .tscn.
## A l'ouverture les offres se retournent ; un achat file vers la rangee haute ; un manuel montre le gain de niveau.

signal changed

## Glyphe des manuels de technique : 法, la methode.
const MANUAL_GLYPH := "法"

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


func _ready() -> void:
	_title.text = "UI_SHOP"
	add_child(_title)
	add_child(_offers)
	add_child(_level_up)
	add_child(_reroll)
	_reroll.pressed.connect(_on_reroll_pressed)


func open(shop: ShopState) -> void:
	_shop = shop
	_level_up.text = ""
	show()
	_refresh()
	_reveal()


func _refresh() -> void:
	for child: Node in _offers.get_children():
		_offers.remove_child(child)
		child.queue_free()
	for i: int in _shop.offers.size():
		var artifact: ArtifactDefinition = _shop.offers[i]
		_add_offer(ItemSlot.Kind.ARTIFACT, artifact.glyph, artifact.name_key, tr(artifact.description_key),
			artifact.price, _shop.can_buy(i), _on_buy_pressed.bind(i), artifact.icon)
	for i: int in _shop.manual_offers.size():
		var hand: HandDefinition = _shop.manual_offers[i].hand
		_add_offer(ItemSlot.Kind.ARTIFACT, MANUAL_GLYPH, hand.name_key,
			tr("UI_MANUAL_DESC") % [tr(hand.name_key), hand.level_qi, hand.level_comprehension],
			_shop.manual_offers[i].price, _shop.can_buy_manual(i), _on_buy_manual_pressed.bind(i))
	for i: int in _shop.pill_offers.size():
		var pill: PillDefinition = _shop.pill_offers[i]
		_add_offer(ItemSlot.Kind.PILL, pill.glyph, pill.name_key, tr(pill.description_key),
			pill.price, _shop.can_buy_pill(i), _on_buy_pill_pressed.bind(i))
	_reroll.text = tr("UI_SHOP_REROLL") % _shop.reroll_cost
	_reroll.disabled = not _shop.can_reroll()


## buy(slot) : achete l'offre ; le slot sert de point de depart a l'envol.
func _add_offer(kind: ItemSlot.Kind, glyph: String, name_key: String, description: String, price: int,
		can_buy: bool, buy: Callable, icon: Texture2D = null) -> void:
	var offer := VBoxContainer.new()
	var slot := ItemSlot.new()
	slot.kind = kind
	slot.glyph = glyph
	slot.picture = icon
	slot.tooltip_text = tr(name_key) + "\n" + description
	slot.disabled = not can_buy
	slot.size_flags_horizontal = SIZE_SHRINK_CENTER
	slot.pressed.connect(func() -> void: buy.call(slot))
	offer.add_child(slot)
	var title := SideColumn.make_label(&"SideCaption", name_key)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offer.add_child(title)
	var cost := HBoxContainer.new()
	cost.alignment = BoxContainer.ALIGNMENT_CENTER
	var amount := SideColumn.make_label(&"Price")
	amount.text = str(price)
	cost.add_child(amount)
	cost.add_child(StoneIcon.new())
	offer.add_child(cost)
	_offers.add_child(offer)


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
		changed.emit()
		_refresh()
		_show_level_up(hand)


func _on_buy_pill_pressed(slot: ItemSlot, index: int) -> void:
	# Comme pour un artefact : envol avant l'achat.
	if _shop.can_buy_pill(index):
		_fly(slot)
	if _shop.buy_pill(index):
		changed.emit()
		_refresh()
