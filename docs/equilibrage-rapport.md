# Rapport d'equilibrage

Genere par tools/equilibrage.gd ; ne pas modifier a la main. Explications : equilibrage.md.

## Joueur de reference au depart (2000 mains, graine 1)

- Score moyen d'une main : 224
- Score d'un round : 10 % des joueurs sous 463, mediane 862, 90 % sous 1360
- Valeur d'une pierre k : +3.7 % de score

## Objectifs

| Royaume | Score de base | Goulots (objectif, pierres) | Croissance vers le suivant |
| --- | --- | --- | --- |
| 1 | 460 | 460 (3), 690 (4), 828 (5) | x1.80 |
| 2 | 830 | 830 (3), 1245 (4), 1245 (5) | x1.80 |
| 3 | 1500 | 1500 (3), 2250 (4), 1650 (5) | x1.80 |
| 4 | 2700 | 2700 (3), 4050 (4), 3510 (5) | x1.80 |
| 5 | 4900 | 4900 (3), 7350 (4), 7840 (5) | x1.80 |
| 6 | 8700 | 8700 (3), 13050 (4), 14790 (5) | x1.80 |
| 7 | 16000 | 16000 (3), 24000 (4), 24000 (5) | x1.80 |
| 8 | 28000 | 28000 (3), 42000 (4), 50400 (5) | x1.80 |

## Objets (gain mesure, prix)

| Objet | Gain | Prix | Rarete |
| --- | --- | --- | --- |
| artefact_arbre_millenaire | +39.7 % | 11 | 2 |
| artefact_arbre_sapeques | +0.0 % | 18 | 3 |
| artefact_balai_bambou | +0.0 % | 5 | 0 |
| artefact_bambou_celeste | +33.8 % | 9 | 2 |
| artefact_banniere_cinq_vents | +30.5 % | 8 | 2 |
| artefact_bassin_purete | +14.2 % | 4 | 0 |
| artefact_boussole | +40.6 % | 11 | 2 |
| artefact_chaudron_alchimique | +21.5 % | 6 | 1 |
| artefact_cloche | +10.8 % | 3 | 0 |
| artefact_couronne_immortel | +17.9 % | 5 | 0 |
| artefact_crapaud_jade | +0.0 % | 6 | 1 |
| artefact_dragon_azur | +6.2 % | 2 | 0 |
| artefact_echelle_celeste | +9.7 % | 3 | 0 |
| artefact_epee_volante | +21.0 % | 6 | 1 |
| artefact_ermite | +8.1 % | 2 | 0 |
| artefact_eventail | +6.7 % | 2 | 0 |
| artefact_ginseng | +12.6 % | 3 | 0 |
| artefact_gourde_elixir | +26.1 % | 7 | 1 |
| artefact_grain_riz | +7.1 % | 2 | 0 |
| artefact_grue | +43.3 % | 12 | 2 |
| artefact_hache | +7.6 % | 2 | 0 |
| artefact_lanterne | +28.1 % | 8 | 1 |
| artefact_lotus_flamme | +9.4 % | 3 | 0 |
| artefact_miroir_jumeau | +29.9 % | 8 | 1 |
| artefact_montagne | +23.8 % | 6 | 1 |
| artefact_nuage_pourpre | +10.4 % | 3 | 0 |
| artefact_oiseau_vermillon | +24.5 % | 7 | 1 |
| artefact_pagode | +12.9 % | 3 | 0 |
| artefact_perle_marees | +23.8 % | 6 | 1 |
| artefact_pierre_eveil | +29.8 % | 8 | 1 |
| artefact_pinceau | +8.1 % | 2 | 0 |
| artefact_qilin | +6.8 % | 2 | 0 |
| artefact_sceau_jade | +52.4 % | 14 | 3 |
| artefact_source_cachee | +13.4 % | 4 | 0 |
| artefact_tigre_blanc | +20.5 % | 6 | 1 |
| artefact_tortue_noire | +7.1 % | 2 | 0 |
| manuel_ascension | +11.1 % | 3 | |
| manuel_ascension_pure | +0.2 % | 1 | |
| manuel_brelan | +2.8 % | 1 | |
| manuel_carre | +1.5 % | 1 | |
| manuel_cinq_souverains | +0.0 % | 1 | |
| manuel_cycle_engendrement | +0.0 % | 1 | |
| manuel_double_paire | +13.4 % | 4 | |
| manuel_full | +9.5 % | 3 | |
| manuel_harmonie | +16.2 % | 4 | |
| manuel_paire | +2.8 % | 1 | |
| manuel_purete | +5.7 % | 2 | |
| manuel_souffle | +0.1 % | 1 | |

## Tribulations (score sous la contrainte / sans, defausse naive)

| Tribulation | Difficulte propre | Multiplicateur d'objectif |
| --- | --- | --- |
| tribulation_demon | x0.55 | x1.1 |
| tribulation_epees | x0.92 | x1.8 |
| tribulation_flammes | x0.92 | x1.8 |
| tribulation_foudre | x0.64 | x1.3 |
| tribulation_gel | x0.81 | x1.6 |
| tribulation_karma | x0.76 | x1.5 |
| tribulation_neant | x0.83 | x1.7 |
| tribulation_vent_noir | x0.76 | x1.5 |

## Mains (rarete exacte sur 5 cartes, valeurs ecrites)

| Main | Rarete | Surprise | Qi x Comprehension | Niveau | Priorite |
| --- | --- | --- | --- | --- | --- |
| main_souffle | 100.0 % | 0.00 | 5 x 1 | +2 / +0 | 10 |
| main_paire | 48.30833 % | 0.73 | 8 x 2 | +2 / +1 | 20 |
| main_double_paire | 4.661649 % | 3.07 | 36 x 3 | +11 / +1 | 30 |
| main_harmonie | 4.44372 % | 3.11 | 37 x 3 | +11 / +1 | 40 |
| main_brelan | 2.443722 % | 3.71 | 37 x 4 | +11 / +1 | 50 |
| main_ascension | 0.28402 % | 5.86 | 68 x 5 | +20 / +2 | 60 |
| main_full | 0.150376 % | 6.50 | 69 x 6 | +21 / +2 | 70 |
| main_purete | 0.082707 % | 7.10 | 82 x 6 | +25 / +2 | 80 |
| main_carre | 0.03771 % | 7.88 | 86 x 7 | +26 / +2 | 90 |
| main_ascension_pure | 0.000454 % | 12.30 | 145 x 10 | +44 / +3 | 100 |
| main_cycle_engendrement | 0.000454 % | 12.30 | 145 x 10 | +44 / +3 | 110 |
| main_cinq_souverains | 0.000116 % | 13.67 | 164 x 11 | +49 / +3 | 120 |

## Mains jouees par le joueur de reference

| Main | Part des mains jouees |
| --- | --- |
| main_harmonie | 28.3 % |
| main_paire | 23.0 % |
| main_double_paire | 22.1 % |
| main_ascension | 7.2 % |
| main_souffle | 6.2 % |
| main_full | 5.6 % |
| main_brelan | 3.9 % |
| main_purete | 2.9 % |
| main_carre | 0.8 % |
| main_ascension_pure | 0.1 % |
