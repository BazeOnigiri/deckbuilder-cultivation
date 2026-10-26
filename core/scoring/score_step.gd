class_name ScoreStep
extends RefCounted
## Une etape du calcul du score, dans l'ordre ou elle a eu lieu. qi et comprehension : valeurs apres l'etape.

enum Kind {BASE, CARD, EFFECT}

var kind: Kind
var qi: int
var comprehension: float
## CARD : la carte qui compte. EFFECT : la carte qui a declenche l'effet, ou null.
var card: CardInstance
## EFFECT seulement : l'effet applique et d'ou il vient (null si inconnu).
var effect: ScoreEffect
var source: Resource
