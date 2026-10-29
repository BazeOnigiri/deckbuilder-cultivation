# Crédits

## Moteur

- **Godot Engine** : licence MIT. <https://godotengine.org/license>
  Le texte de licence de Godot doit figurer dans les crédits du jeu publié.

## Outils de développement (non inclus dans le jeu publié)

- **GUT (Godot Unit Test)** 9.7.1 par bitwes : licence MIT. <https://github.com/bitwes/Gut>

## Polices (incluses dans le projet)

- Noto Serif, Google, SIL Open Font License 1.1, <https://fonts.google.com/specimen/Noto+Serif> (sous-ensemble latin, texte de licence : `ui/fonts/OFL-NotoSerif.txt`)
- Ma Shan Zheng, Ma Shan Zheng, SIL Open Font License 1.1, <https://fonts.google.com/specimen/Ma+Shan+Zheng> (sous-ensemble de 86 sinogrammes, texte de licence : `ui/fonts/OFL-MaShanZheng.txt`)

## Conception et usage d'IA

- Conception du jeu : BazeOnigiri.
- Le code, les dessins SVG, les shaders, les sons et les textes ont été réalisés avec l'aide d'une IA
  (Claude, Anthropic). La maquette visuelle a été générée avec Claude Design. À signaler sur la page itch.io.

## Images et shaders

- Tous les SVG sont écrits par l'IA (Claude) à partir des consignes de BazeOnigiri : `icon.svg`,
  `content/artifacts/icones/` (artefacts), `ui/cards/figures/`, `ui/cards/icons/`, `ui/kit/`, `ui/icons/`,
  `ui/round/`, `ui/shop/`. Aucun asset graphique externe.
- Les shaders (`*.gdshader`) sont écrits par l'IA (Claude).

## Sons

- Les sons du jeu sont fabriqués par `tools/sons/generate_sounds.py` à partir des échantillons ci-dessous
  (découpés, transposés, superposés, réverbérés) et de synthèse. Le script, ses recettes et la musique ont été
  écrits avec l'aide d'une IA (Claude) : à signaler sur la page itch.io.
- **Casino Audio** et **Impact Sounds**, Kenney (kenney.nl), licence CC0 1.0.
  <https://kenney.nl/assets/casino-audio>, <https://kenney.nl/assets/impact-sounds>
- **Versilian Community Sample Library (VCSL)**, Versilian Studios, licence CC0 1.0 : Dan Tranh, woodblock,
  slit drum, tambour sur cadre, cloches népalaises, cymbalettes, carillon, verres chantés, gong.
  <https://github.com/sgossner/VCSL>
- Liste exacte des fichiers : `tools/sons/sources.json` (téléchargés par `tools/sons/fetch_sources.py`).
