# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versions selon [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

### Ajouté

- Polices Noto Serif et Ma Shan Zheng (OFL) en sous-ensembles, chiffres tabulaires pour que les scores ne tremblent pas.
- Theme de base « lavis de nuit » applique a tout le projet : palette nuit, jade et or, styles des boutons, fenetres, onglets et infobulles.
- Cartes dessinees par le moteur : rang et symbole de l'element dans deux coins opposes, points repetes pour les rangs 1 a 6, figures Disciple, Maitre et Immortel pour les rangs 7 a 9, carte qui monte et sceau 选 quand elle est selectionnee. Styles des elements (couleur, symbole) en donnees dans ui/cards/styles/, apparence de la carte dans le Theme (type CardButton).
- Fond anime « lavis » derriere tous les ecrans : encre qui se diffuse lentement sur le bleu nuit. Papier de riz pose sur tout le jeu (grain, fibres, vignette). Reglages dans ui/theme/lavis.tres et papier.tres.
- Ecran Options accessible depuis le menu, avec le reglage « Reduire les animations » (fige le fond anime). Reglages sauvegardes dans un fichier versionne, a part du profil.
- Main vivante : cartes en eventail qui rejoignent leur place avec un ressort, arrivent depuis la pioche, flottent doucement, grossissent au survol et s'inclinent en fausse 3D vers la souris. La carte selectionnee monte en douceur. « Reduire les animations » coupe le flottement et l'inclinaison. Reglages du mouvement dans ui/cards/hand_feel.tres.
- Sequence de score : les cartes jouees montent au-dessus de la main, chaque carte qui compte bondit avec son +Qi, chaque artefact declenche montre son nom et son effet, le compteur Qi x Comprehension defile, puis l'ecran tremble selon le score et le fond se teinte de l'element dominant. Le coup est sauvegarde des qu'il est joue. Rythme dans ui/round/score_feel.tres.
- Effets de cartes : une carte qui quitte la main (jouee, defaussee, detruite par une pilule) se dissout comme du papier qui brule, bord de la couleur de son element. Chaque carte qui compte lache une gerbe de qi. Une carte modifiee par une pilule luit de la couleur de son element.
- Le pipeline de score note chaque etape (base, cartes, effets) avec l'artefact et la carte qui l'ont declenchee.
- Colonne laterale dans l'ecran de round : goulot et sa contrainte (bandeau rouge pendant une tribulation), anneau d'objectif qui se remplit, Qi du round qui defile quand le total d'un coup s'y envole, apercu de la main selectionnee (nom, niveau, Qi x Comprehension), mains, defausses, pierres, royaume et goulot. Boutons Voie de cultivation (infos de la run) et Options, ouvertes par-dessus la run sans la quitter.
- Rangee haute dans l'ecran de round : emplacements d'artefacts (3/5) et de pilules (1/2), chacun avec son caractere calligraphie et son infobulle, emplacements libres en pointilles. Un clic sur une pilule l'utilise sur la selection. Pendant la sequence de score, l'emplacement d'un artefact qui se declenche bondit et son effet s'affiche dessous. Police des sceaux etendue a 15 caracteres.

## [0.3.0] - 2026-10-25

### Ajouté

- Royaumes et goulots en donnees (3 royaumes x 3 goulots), objectif = score de base du royaume x multiplicateur du goulot.
- L'ecran de round affiche le royaume et le goulot, et lit son objectif dans les donnees.
- Flux de jeu : menu principal, enchainement des 9 goulots, victoire ou defaite de la run, retour au menu.
- Economie : pierres spirituelles gagnees a chaque goulot (base du goulot, mains restantes, interets plafonnes), regles en donnees.
- Artefacts en donnees : declencheur (main jouee, carte comptee), condition (main, element) et effet de score. 5 premiers artefacts.
- Liste des artefacts possedes a l'ecran, avec leur description en infobulle. Artefacts de debug reglables dans l'inspecteur.
- Boutique entre deux goulots : 2 offres d'artefacts tirees au hasard, achat avec les pierres spirituelles, relance au cout croissant, 5 artefacts maximum.
- Niveaux de main et manuels de technique : un manuel achete en boutique fait monter sa main d'un niveau (+Qi, +Comprehension).
- Generateur tools/generate_manuals.gd : un manuel par main.
- Pilules : consommables utilises pendant un round sur les cartes selectionnees (changer l'element, monter le rang, detruire). 4 pilules, vendues en boutique, 2 places d'inventaire.
- Tribulations : le dernier goulot de chaque royaume impose une contrainte (sceau d'element, une main de moins, main reduite). Contraintes en donnees.
- Socle de sauvegarde : JSON avec numero de version et migrations, ecriture via fichier temporaire pour ne jamais corrompre une sauvegarde.
- Profil : parties lancees, victoires, meilleur royaume, meilleure main et mains jouees par type, sauvegardes et affiches dans une page Statistiques accessible depuis le menu.
- Fenetre Infos pendant la run : niveau et valeur de chaque main, goulots du royaume en cours avec objectifs et contraintes, statistiques de la run.
- Sauvegarde de run (logique) : capture et restauration entre deux goulots, par id, avec l'etat exact de la RNG et les offres de la boutique.
- Reprendre une run : sauvegarde automatique apres chaque action (round en cours avec ses piles exactes, ou boutique), bouton Continuer dans le menu, fenetre Nouvelle partie avec un onglet Continuer qui resume la run sauvegardee.

### Modifié

- Les cartes en jeu ont leur propre element et rang, copies de leur definition : prepare les pilules.
- Le bouton Credits est dans le menu principal, et non plus dans l'ecran de round.
- Comptage des mains (HandTally) et valeurs par niveau (HandDefinition.qi_at) partages au lieu d'etre dupliques.
- Le contenu du jeu (regles, catalogues, paquet) est charge une seule fois par main et injecte dans les ecrans.

### Corrigé

- Le dossier build/ est ignore par Godot, les exports ne sont plus importes comme ressources du jeu.
- Une pilule qui detruit toute la main fait repiocher, ou perdre le round si la pioche est vide, au lieu de bloquer la partie.

## [0.2.0] - 2026-10-21

### Ajouté

- Preset d'export Web (sans threads), avec tools/, test/ et addons/gut/ exclus du jeu publie.
- Bouton Credits affichant la licence de Godot.

---

## [0.1.0] - 2026-10-20

### Ajouté

- Arborescence par domaine : core, content, ui, test.
- Configuration godot-tools et lancement debug depuis l'IDE.
- Framework de tests GUT 9.7.0 avec un test de fumée exécutable en headless.
- Éléments (bois, feu, terre, métal, eau) et cycle d'engendrement en donnée.
- Modèle de carte et de paquet, paquet de départ de 45 cartes généré par script.
- Etat du paquet en partie (pioche, main, defausse) avec melange a seed injectee.
- CardInstance : carte en jeu distincte de sa definition.
- Regles de round en donnees (taille de main) dans content/rules/.
- Detection des 12 mains, definies en donnees dans content/hands/ avec des detecteurs configurables.
- Chargement automatique du contenu d'un dossier (compatible export web).
- Fichier de traduction FR/EN des noms de mains.
- Pipeline de scoring Qi x Comprehension a phases fixes (additions puis multiplications), avec effets injectes.
- Round : jouer ou defausser, mains et defausses limitees, victoire a l'objectif, defaite sinon. Regles en donnees.
- Premier ecran jouable : selection des cartes, jouer, defausser, score, victoire ou defaite, rejouer.
