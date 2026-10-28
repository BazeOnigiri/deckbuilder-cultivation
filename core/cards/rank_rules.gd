class_name RankRules
extends Resource
## Rangs d'un paquet : rang le plus haut et Qi qu'apporte une carte qui compte, selon son rang.
## Comme Balatro : les chiffres (1 a 10) valent leur rang, les figures 10, le Souverain (l'As) 11.

@export var max_rank: int = 0
## Qi d'une carte qui compte : qi_by_rank[rang - 1].
@export var qi_by_rank: PackedInt32Array = []


func qi_of(rank: int) -> int:
	if rank < 1 or rank > qi_by_rank.size():
		return rank
	return qi_by_rank[rank - 1]


func is_valid() -> bool:
	return max_rank > 0 and qi_by_rank.size() == max_rank
