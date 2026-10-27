---
name: sons-et-musique
description: Concevoir, generer et brancher les sons et la musique de Wu Xing (tools/sons/, content/sons/, Sons autoload). A utiliser pour tout ajout ou retouche d'un bruitage, d'une variante, d'un arrangement de musique, ou un retour du type « ce son est moche / trop repetitif ».
---

# Sons et musique de Wu Xing

## Principes (son de jeu en general)

1. **Jamais deux fois le meme son de suite** (« effet mitraillette ») : un son frequent (clic, survol, carte,
   decompte) a plusieurs variantes enregistrees, tirees sans repetition immediate, plus une petite variation
   de hauteur (2 a 6 %) et de volume (1 a 2 dB). La hauteur seule ne suffit pas : il faut des prises differentes.
2. **Plus un son est frequent, plus il est court, sec et discret** (survol < clic < carte < score < fin de goulot).
3. **Le son confirme l'action, a l'image pres** : l'attaque du fichier tombe sur l'evenement (silence d'entree coupe).
4. **Chaque famille d'action a son timbre** : bois pour l'interface, papier pour les cartes, jade/verre pour le Qi,
   tambour + gong pour la Comprehension, gong + carillon pour les grands moments.
5. **Musique : un seul theme, des arrangements** par ecran, synchronises ; changer d'ecran = fondu, jamais de reprise
   au debut. La musique laisse la place aux effets (filtree, peu d'aigus, volume -5 a -6 dB).

## Ce que fait Balatro (mecaniques a reprendre, habillage a nous)

- Decompte : chaque carte qui compte joue une note **qui monte** ; les multiplicateurs ont un son a part, plus lourd.
  Ici : `note_carte` / `orbe_impact` avec une gamme pentatonique (`scale`), `multiplication` pour la Comprehension.
- Foley reel (cartes, jetons) court et sec, avec variantes ; jamais de bip synthetique.
- Une seule piece de musique, variantes par contexte (boss, boutique, paquets), grain chaud et detune.
- Le son travaille avec le reste (secousse, particules, chiffres qui defilent) : aucun canal seul ne porte l'effet.

## Marche a suivre dans le projet

- Recettes : `tools/sons/recettes.json`. Kinds `sample`, `layers`, `partition`. Post : highpass, lowpass, drive, reverb.
- Variantes : `"variantes": [{...}, ...]` dans une recette ; chaque objet remplace des champs de la recette
  (file, start, pitch, layers...). Fichiers `<id>_1.wav`, `<id>_2.wav`..., une seule fiche `<id>.tres` qui les liste.
- Musique : `tools/sons/partition.json` (pistes generiques arpeges, nappes, frappes, par_mesures, bruits ;
  bloc `arrangements`), recette `musique_<arrangement>`, champ `music` de l'ambiance (`ui/ambiances/*.tres`).
- Generer depuis la racine : `python -I tools/sons/generate_sounds.py [ids]` (sources : `fetch_sources.py`,
  puis `ogg_capture.gd` + `split_capture.py` pour les .ogg Kenney). Echantillons CC0 seulement, notes dans CREDITS.md.
- Apres un premier import : `edit/loop_mode=2` dans les `.import` des musiques, puis reimport.
- Jouer : `Sons.play(id, step)` (step = note dans la gamme), `Sons.play_music(id, fondu)`. Les boutons sont branches
  tout seuls (clic, survol ; selection/deselection pour les cartes).
- Verifier sans oreilles : `--write-movie` ecrit aussi la piste audio mixee ; mesurer RMS, centroide, correlation
  avec chaque fichier. Toujours dire a l'utilisateur que rien n'a ete ecoute.
- Tests : `test/unit/content/test_sounds_content.gd` (fiches, boucles, variantes), `test/unit/ui/test_sound_bank.gd`.
