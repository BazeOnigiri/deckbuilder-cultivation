class_name UnlockContext
extends RefCounted
## Ce qu'une condition peut lire : le profil et, pendant une partie, la run et ses compteurs.

var profile: ProfileStats
## null hors d'une run : les conditions de partie sont alors fausses.
var run: RunState
var won: bool = false
## Artefacts achetes en boutique dans cette partie.
var purchases: int = 0
var one_hand_clears: int = 0


func _init(for_profile: ProfileStats, for_run: RunState = null) -> void:
	profile = for_profile
	run = for_run
