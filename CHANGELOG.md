# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versions selon [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

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

### Modifié

- Les cartes en jeu ont leur propre element et rang, copies de leur definition : prepare les pilules.
- Le bouton Credits est dans le menu principal, et non plus dans l'ecran de round.
- Comptage des mains (HandTally) et valeurs par niveau (HandDefinition.qi_at) partages au lieu d'etre dupliques.

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
