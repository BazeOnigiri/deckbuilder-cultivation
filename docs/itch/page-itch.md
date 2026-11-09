# Page itch.io : textes à copier

Champs dans l'ordre du formulaire « Edit game » d'itch.io. La page est en anglais (public d'itch.io majoritairement
anglophone), avec un résumé français en bas de la description.

## Title

```
五行 Wu Xing
```

## Short description or tagline

```
A cultivation roguelike deckbuilder: forge hands from the Five Elements and break through the heavens.
```

## Classification

- Kind of project : `HTML`
- Release status : `Released` (ou `In development` si tu veux garder une marge pour les retours)
- Pricing : `No payments` ou `$0 or donate`

## Genre

`Card Game`

## Tags (10 max)

```
deckbuilder, roguelike, roguelite, card-game, xianxia, cultivation, wuxia, chinese, singleplayer, godot
```

## App store / Inputs / Accessibility (cases à cocher)

- Inputs : `Mouse`, `Keyboard`, `Xbox controller`, `Touchscreen`
- Accessibility : `Configurable controls`, `High-contrast`, `Subtitles` non (pas de voix)
- Languages : `English`, `French`
- Average session : `About a half-hour`

## Description

Coller dans l'éditeur de description (il accepte le Markdown collé tel quel, sinon reformate titres et listes à la
main).

```
A cultivator's path is long. Seventy cards, five elements, eight realms, one breakthrough at a time.

**五行 Wu Xing** is a solo roguelike deckbuilder steeped in xianxia cultivation. Draw from a deck of 70 cards (Wood, Fire, Earth, Metal and Water, ranks 1 to 14 up to the four sage figures 徒 师 仙 尊), form hands and gather enough power to break through each bottleneck.

### How it plays

- **Score = Qi × Comprehension.** Every hand has its base Qi and Comprehension; the cards that count add their rank.
- **12 hands to master**, from a simple Breath to the Pair, Harmony (five different elements), Ascension, Purity, and the legendary **Generation Cycle**: five consecutive ranks whose elements follow Wood → Fire → Earth → Metal → Water.
- **8 realms**, three bottlenecks each, ending in a **Heavenly Tribulation** that bends the rules.
- **Spirit stones and a shop** between rounds: 36 artifacts and spirit beasts, 27 pills, 12 technique manuals, 8 legacies and treasure seals.
- **Enhance your cards**: jade, black iron, primordial chaos, auras and talismans.
- **Encounters and omens**: a hermit in the mist, a black market of pills, a fox spirit with a deal to offer... or skip a bottleneck and read its omen.

### For the long road

- 8 difficulty levels and 5 challenges
- Endless mode beyond the last realm
- Daily run (same seed for everyone) and custom seeds
- 21 achievements, unlocks, compendium, run history and statistics
- Fully playable with mouse, keyboard, gamepad or touch; remappable keys, high contrast, reduced animations
- English and French

### Controls

Mouse, or keyboard: 1–8 select cards, Enter plays, D discards, R / E sort by rank / element, Tab shows the deck.
Gamepad: A select, Y play, X discard. Every key can be remapped in Options.

Your progress is saved in your browser.

---

**FR** — Roguelike deckbuilder solo au thème de la cultivation (xianxia). Formez des mains avec un paquet de 70 cartes aux cinq éléments, combinez artefacts, pilules et manuels de technique, et franchissez les huit royaumes jusqu'à la tribulation céleste. Jeu entièrement disponible en français (Options > Langue).

---

Made with Godot 4.7. Fonts: Noto Serif and Ma Shan Zheng (SIL Open Font License). Full credits in the game.
AI disclosure: parts of the code, SVG art, shaders, sounds and texts were made with the help of generative AI.
```

## AI generation disclosure

Répondre **Yes** et cocher ce qui correspond à CREDITS.md (code, graphismes SVG, sons, textes).

## Captures d'écran

Dans `docs/itch/captures/`, 1152 × 648, jeu en anglais, prises sur l'export web. Ordre conseillé sur la page :

1. `02-round.png` : round avec deux artefacts, une paire sélectionnée et l'infobulle d'un artefact.
2. `03-score.png` : décompte d'un brelan (bannière de la main).
3. `05-boutique.png` : la boutique.
4. `04-goulot.png` : annonce du goulot, présages et tribulation à venir.
5. `06-mains.png` : la Voie de cultivation, onglet des mains.
6. `01-menu.png` : le menu principal.

Manquent encore une rencontre et un bilan de victoire, à prendre en jouant.

`docs/itch/` contient un `.gdignore` : Godot n'importe pas ces images et elles ne partent pas dans l'export.

## Image de couverture

`docs/itch/couverture.png` (630 × 500), générée par `python -I tools/itch/couverture.py .` (Pillow, polices de
ui/fonts). Elle sert aussi de « Cover image » ; pour la bannière de page (960 × 200 environ) et le fond, reprendre
la palette : bleu nuit #17212C, or #C9A65A, jade #5E9C8A.
