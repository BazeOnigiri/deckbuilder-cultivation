extends SceneTree
## Génère les 70 cartes du paquet de départ (une par fichier) et paquet_depart.tres.
## Usage : godot --headless --path . -s tools/generate_starter_deck.gd
## Relancer écrase les fichiers existants : à n'utiliser que pour (re)créer le contenu.

const CARDS_DIR: String = "res://content/cards/"
const DECK_PATH: String = "res://content/decks/paquet_depart.tres"
const DECK_ID: StringName = &"paquet_depart"
const RANK_MIN: int = 1
const RANK_MAX: int = 14
## Qi de chaque rang (figures 11 a 13, Souverain 14) : le paquet le reference.
const RANKS_PATH: String = "res://content/rules/rangs.tres"


func _initialize() -> void:
	var error: Error = _generate()
	if error == OK:
		print("Paquet de départ généré : %s" % DECK_PATH)
	else:
		push_error("Échec de la génération : %s" % error_string(error))
	quit(0 if error == OK else 1)


func _generate() -> Error:
	for dir: String in [CARDS_DIR, DECK_PATH.get_base_dir()]:
		var dir_error: Error = DirAccess.make_dir_recursive_absolute(dir)
		if dir_error != OK:
			return dir_error

	var deck: DeckDefinition = DeckDefinition.new()
	deck.id = DECK_ID
	deck.ranks = load(RANKS_PATH)

	for value: int in Element.Type.values():
		var element: Element.Type = value as Element.Type
		for rank: int in range(RANK_MIN, RANK_MAX + 1):
			var card_id: StringName = StringName("carte_%s_%d" % [Element.to_id(element), rank])
			var path: String = CARDS_DIR + String(card_id) + ".tres"
			var save_error: Error = ResourceSaver.save(CardData.create(card_id, element, rank), path)
			if save_error != OK:
				return save_error
			# Recharger depuis le disque : la carte obtenue a son chemin de fichier,
			# donc le paquet la référencera au lieu d'en intégrer une copie.
			var saved: CardData = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as CardData
			if saved == null:
				return ERR_FILE_CANT_READ
			deck.cards.append(saved)

	return ResourceSaver.save(deck, DECK_PATH)