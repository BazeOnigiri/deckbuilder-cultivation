class_name HandDetector
extends Resource
## Base des detecteurs. Renvoie les cartes qui comptent, ou un tableau vide si la main ne correspond pas.


func detect(_cards: Array[CardInstance]) -> Array[CardInstance]:
	var empty: Array[CardInstance] = []
	return empty