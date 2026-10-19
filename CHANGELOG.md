# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versions selon [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

### Ajouté

- Arborescence par domaine : core, content, ui, test.
- Configuration godot-tools et lancement debug depuis l'IDE.
- Framework de tests GUT 9.7.0 avec un test de fumée exécutable en headless.
- Éléments (bois, feu, terre, métal, eau) et cycle d'engendrement en donnée.
- Modèle de carte et de paquet, paquet de départ de 45 cartes généré par script.
- Etat du paquet en partie (pioche, main, defausse) avec melange a seed injectee.
- CardInstance : carte en jeu distincte de sa definition.
- Regles de round en donnees (taille de main) dans content/rules/.
