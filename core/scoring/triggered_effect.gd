class_name TriggeredEffect
extends RefCounted
## Un effet de score declenche, avec ce qui l'a declenche : sert a montrer au joueur pourquoi il a marque.

var effect: ScoreEffect
## D'ou vient l'effet (un artefact). null si inconnu.
var source: Resource
## La carte qui l'a declenche (declencheur CARD_SCORED), sinon null.
var card: CardInstance


func _init(p_effect: ScoreEffect, p_source: Resource = null, p_card: CardInstance = null) -> void:
	effect = p_effect
	source = p_source
	card = p_card
