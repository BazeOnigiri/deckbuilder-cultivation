class_name ShopPanel
extends VBoxContainer
## Boutique affichee entre deux goulots. Construite en code : pas de .tscn a maintenir.

signal changed

var _shop: ShopState
var _title := Label.new()
var _offers := HBoxContainer.new()
var _reroll := Button.new()


func _ready() -> void:
	_title.text = "UI_SHOP"
	add_child(_title)
	add_child(_offers)
	add_child(_reroll)
	_reroll.pressed.connect(_on_reroll_pressed)


func open(shop: ShopState) -> void:
	_shop = shop
	show()
	_refresh()


func _refresh() -> void:
	for child: Node in _offers.get_children():
		_offers.remove_child(child)
		child.queue_free()
	for i: int in _shop.offers.size():
		var artifact: ArtifactDefinition = _shop.offers[i]
		var button := Button.new()
		button.text = tr("UI_SHOP_OFFER") % [tr(artifact.name_key), artifact.price]
		button.tooltip_text = tr(artifact.description_key)
		button.disabled = not _shop.can_buy(i)
		button.pressed.connect(_on_buy_pressed.bind(i))
		_offers.add_child(button)
	_reroll.text = tr("UI_SHOP_REROLL") % _shop.reroll_cost
	_reroll.disabled = not _shop.can_reroll()


func _on_buy_pressed(index: int) -> void:
	if _shop.buy(index):
		changed.emit()
		_refresh()


func _on_reroll_pressed() -> void:
	if _shop.reroll():
		changed.emit()
		_refresh()