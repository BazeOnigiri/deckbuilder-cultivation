class_name ShopFeel
extends Resource
## Rythme de la boutique. Valeurs dans shop_feel.tres.

## A l'ouverture, chaque offre se retourne (echelle horizontale de 0 a 1), l'une apres l'autre.
@export var flip_time: float = 0.3
@export var flip_stagger: float = 0.08
## Un achat file vers son emplacement de la rangee haute.
@export var fly_time: float = 0.45
## Message « la main monte de niveau » apres un manuel : apparition puis duree d'affichage.
@export var level_up_fade: float = 0.3
## Les lanternes de l'enseigne se balancent : angle maximal (radians) et duree d'un aller.
@export var lantern_swing: float = 0.08
@export var lantern_time: float = 1.6
## Taille des cartes proposees par un sceau de disciples (1 = taille d'une carte en main).
@export var pack_card_scale: float = 0.6
