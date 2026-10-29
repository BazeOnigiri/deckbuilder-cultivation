# Projet : deckbuilder cultivation (Balatro-like)

## Contexte

- Je suis étudiant en génie logiciel et j'apprends Godot avec ce projet.
- Objectif 1 : apprendre Godot et l'architecture d'un jeu. Objectif 2 : finir une v1 jouable pendant les vacances.
- Le projet continuera après la v1 : l'architecture doit permettre de l'étendre.
- Jeu solo, export web publié sur itch.io.
- C:\Users\Timki\Desktop\Code\Godot Projects\deckbuilder-cultivation

## Concept

- Roguelike deckbuilder inspiré de Balatro, thème cultivation (manhua xianxia).
- Paquet de 70 cartes : 5 éléments (bois, feu, terre, métal, eau) × rangs 1 à 14. Rangs 1 à 10 en chiffres, 11 à 14 en figures (Disciple 徒, Maître 师, Immortel 仙, Souverain 尊). Qi d'une carte : son rang, 10 pour une figure, 11 pour le Souverain (content/rules/rangs.tres). Le Souverain compte aussi sous le 1 dans une Ascension, sans boucle.
- Cycle d'engendrement : bois > feu > terre > métal > eau > bois.
- Score = Qi × Compréhension. Qi = Qi de base de la main + rangs des cartes qui comptent.
- Antes = royaumes. Blinds = goulots d'étranglement. Boss = tribulation céleste avec contrainte.
- Jokers = artefacts / bêtes spirituelles. Planètes = manuels de technique. Tarots = pilules.

## Mains (valeurs calculées par la rareté, voir docs/equilibrage.md)

Une main jouée prend la combinaison la plus haute qu'elle remplit. Qi, Compréhension, gains de niveau et priorité
sont écrits par tools/equilibrage.gd depuis la rareté exacte de chaque main : ne pas les modifier à la main
(valeurs actuelles dans docs/equilibrage-rapport.md).

| Main | Définition | Rareté* | Qi | Compr. |
| --- | --- | --- | --- | --- |
| Souffle | carte la plus haute | 100 % | 5 | 1 |
| Paire | 2 cartes même rang | 48 % | 8 | 2 |
| Double paire | 2 paires | 4,7 % | 36 | 3 |
| Harmonie | 5 éléments différents | 4,4 % | 37 | 3 |
| Brelan | 3 cartes même rang | 2,4 % | 37 | 4 |
| Ascension | 5 rangs consécutifs (le Souverain compte aussi sous le 1) | 0,28 % | 68 | 5 |
| Full | brelan + paire | 0,15 % | 69 | 6 |
| Pureté | 5 cartes même élément | 0,083 % | 82 | 6 |
| Carré | 4 cartes même rang | 0,038 % | 86 | 7 |
| Ascension pure | 5 rangs consécutifs, même élément | 0,00045 % | 145 | 10 |
| Cycle d'engendrement | 5 rangs consécutifs dont les éléments suivent le cycle | 0,00045 % | 145 | 10 |
| Cinq Souverains | 5 cartes même rang (donc les 5 éléments) | 0,00012 % | 164 | 11 |

*Part exacte des tirages de 5 cartes du paquet de 70 qui contiennent la combinaison.

## Scope v1

- 3 royaumes, toutes les mains ci-dessus, 15 à 20 artefacts, 1 seul paquet.
- État actuel (v1.1.0) : 8 royaumes, 36 artefacts, 13 pilules, 8 héritages, 4 sceaux-trésor.
- Hors scope v1 : multijoueur, decks alternatifs, monétisation, carte du monde. Ne pas les coder, mais l'architecture ne doit pas les bloquer.
- Signale toute feature hors scope et demande si elle sert un pilier du jeu.

## Stack

- Godot 4.7.1, GDScript avec typage statique partout.
- Tests : GUT 9.7.x. res://test/unit/core/ (miroir de res://core/) pour la logique, res://test/unit/content/ pour la validation des données.

## Git

- Production : versions publiées uniquement, toujours stable.
- Develop : branche d'intégration et branche par défaut.
- feature/<nom-court> créée depuis Develop pour chaque feature, fix/<nom> pour un bug.
- hotfix/<nom> créée depuis Production pour un bug publié.
- Commits au format Conventional Commits, ex : feat(scoring): ajoute la main Harmonie.
- Branches courtes (1 à 3 jours). Si une feature grossit, propose de la découper.
- Shell : PowerShell sous Windows (pas de `~` pour les chemins passés à gh/git, utiliser `$HOME`).

### Protection GitHub (ruleset "protection-branches-principales", id 25345004)

- Production et Develop : PR obligatoire, push direct rejeté, force push interdit, suppression interdite.
- Seul le merge commit est autorisé (équivalent de merge --no-ff), squash et rebase merge désactivés.
- La branche distante est supprimée automatiquement après merge de la PR.
- Définition du ruleset dans $HOME\ruleset.json. Modification : gh api --method PUT "repos/{owner}/{repo}/rulesets/25345004" --input "$HOME\ruleset.json".
- CI : workflow .github/workflows/test.yml, job "gut", obligatoire pour merger (required_status_checks, branche à jour avec la base exigée). Renommer le job impose de mettre à jour le ruleset.

### Merge d'une feature ou d'un fix dans Develop

1. git fetch origin puis git rebase origin/Develop sur la branche.
2. Tests GUT verts en headless.
3. git push --force-with-lease -u origin <branche> (force autorisé uniquement sur sa propre branche non mergée).
4. gh pr create --base Develop --fill
5. gh pr merge --merge --delete-branch
6. En local : git switch Develop, git pull, git branch -d <branche>.

### Release

1. Branche chore/release-vX.Y.Z depuis Develop : mise à jour de CHANGELOG.md, PR vers Develop, merge.
2. gh pr create --base Production --head Develop --title "release: vX.Y.Z"
3. gh pr merge --merge (sans --delete-branch : Develop est protégée et ne doit pas être supprimée).
4. En local : git switch Production, git pull, git tag -a vX.Y.Z -m "vX.Y.Z", git push origin vX.Y.Z.
5. gh pr create --base Develop --head Production --title "chore: synchronise Production dans Develop" --body "Report du merge de la v0.1.0."
6. gh pr checks --watch ; gh pr merge --merge
7. git switch Develop ; git pull

### Hotfix

1. hotfix/<nom> depuis Production, test qui reproduit le bug puis correction, entrée CHANGELOG.
2. PR vers Production, merge, tag vX.Y.(Z+1) comme pour une release.
3. PR de Production vers Develop pour reporter le correctif, merge.

### Interdits

- Jamais de commit ni de push direct sur Develop ou Production (bloqué par GitHub de toute façon).
- Jamais de rebase ni de force push d'une branche déjà mergée ou partagée.
- À la fin d'une feature, rappelle-moi les étapes Git dans l'ordre.

## Tests (obligatoire)

- Chaque feature ajoute ses tests dans la même branche. Une branche sans tests n'est pas mergeable.
- Chaque bug corrigé ajoute d'abord un test qui reproduit le bug, puis la correction.
- Priorité des tests : détection des mains, pipeline de scoring, économie, RNG avec seed, sauvegarde/chargement.
- L'UI et les animations ne sont pas testées unitairement, mais la logique qu'elles appellent l'est.
- Tous les tests passent en ligne de commande (headless) avant chaque merge dans Develop.
- Dès que le projet tourne : CI GitHub Actions qui lance GUT sur chaque PR vers Develop et Production.
- Si je te demande une feature sans parler des tests, propose les tests quand même.

## Définition de « fini » pour une feature

- Code + tests verts + debug menu à jour si utile + contenu de démo + entrée dans CHANGELOG.md.

## Règles d'architecture

- La logique de jeu (scoring, deck, économie, règles) est séparée de l'affichage et testable sans scène.
- Contenus data-driven : cartes, artefacts, pilules, mains et royaumes sont des Resources. Ajouter un contenu ne modifie jamais le code du combat.
- Pipeline de scoring à ordre déterministe, par phases explicites (additions puis multiplications).
- RNG avec seed, injectée, jamais d'appel aléatoire global dans la logique.
- Machine à états pour le flux : menu, run, round, boutique, game over.
- Communication entre systèmes par signaux, pas de références directes croisées.
- Textes affichés externalisés pour une traduction FR/EN future.

## Scalabilité

Principe : garder les portes ouvertes sans coder pour des besoins qui n'existent pas encore. Si une abstraction ne sert qu'à « plus tard », signale-le et propose la version simple.

- Arborescence par domaine : res://core/ (logique pure), res://content/ (données .tres), res://ui/, res://test/.
- Chaque contenu a un ID texte stable (ex : "artefact_epee_volante"), jamais un chemin de fichier. Les sauvegardes et le code référencent l'ID.
- Registres de contenu chargés automatiquement depuis res://content/ : ajouter une carte, un artefact ou un royaume = ajouter un fichier, rien à déclarer ailleurs.
- Mains définies comme données (nom, priorité, Qi, Compréhension) + un détecteur par main. Ajouter une main ne touche pas au pipeline de scoring.
- Effets des artefacts et pilules composés en données : déclencheur (main jouée, carte comptée, fin de round...) + condition + effet. Un nouvel artefact simple ne demande pas de code.
- Le paquet de départ est une donnée, pas une constante, pour permettre des decks alternatifs plus tard.
- Sauvegarde avec numéro de version et fonction de migration dès la v1.
- Équilibrage centralisé : aucun nombre magique dans le code, tout est dans les Resources ou un fichier de config.
- Entrées via InputMap uniquement (souris aujourd'hui, manette ou tactile plus tard).
- Interface en conteneurs Godot et ancres, pour supporter plusieurs résolutions et un futur portage desktop/mobile.
- Le contenu répétitif (ex : les 70 cartes) est produit par des scripts de res://tools/ (extends SceneTree, lancés en headless). Le jeu ne lit que les .tres générés. tools/, test/ et addons/gut/ sont exclus de l'export.

## Assets (je ne sais pas en créer, aide-moi)

- Direction artistique minimaliste pour rester réalisable : cartes dessinées par le moteur (StyleBox, shaders) + symboles SVG des éléments.
- Tu m'aides à : écrire les SVG (symboles, cadres de cartes, icônes), écrire des shaders (lueur, dissolution, fond animé), définir une palette, choisir des polices sous licence OFL, créer des sons avec jsfxr (donne les réglages), trouver des assets CC0 (Kenney, OpenGameArt filtré CC0).
- Chaque élément a une couleur ET un symbole distinct (daltonisme).
- Toute ressource externe va dans CREDITS.md avec sa licence et sa source.
- Si un asset est généré par IA, le signaler pour la page itch.io.
- Jamais d'assets, noms ou textes de Balatro ni des manhua. Mécaniques inspirées oui, habillage original.
