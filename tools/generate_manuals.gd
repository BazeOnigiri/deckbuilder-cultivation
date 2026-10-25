extends SceneTree
## Genere un manuel par main dans content/manuals/.
## Lancer : godot --headless --path . -s tools/generate_manuals.gd

const OUTPUT_DIR := "res://content/manuals"
const PRICE := 3


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	for hand: HandDefinition in HandCatalog.load_definitions():
		var suffix: String = hand.id.trim_prefix("main_")
		var manual := ManualDefinition.new()
		manual.id = StringName("manuel_" + suffix)
		manual.hand = hand
		manual.price = PRICE
		var path: String = OUTPUT_DIR.path_join("manuel_%s.tres" % suffix)
		var error := ResourceSaver.save(manual, path)
		if error != OK:
			push_error("Echec de l'ecriture de %s : %s" % [path, error_string(error)])
	quit()