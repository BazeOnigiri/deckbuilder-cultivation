# L'équilibrage de Wu Xing, expliqué

Aucun objectif, prix ou récompense n'est écrit à la main. Ils viennent de **formules** appliquées à des **mesures**.
Les mesures sont celles d'un joueur virtuel qui joue des milliers de mains. Ce document explique chaque formule,
ce qu'elle veut dire, et comment la régler.

- Paramètres (les seuls nombres à toucher) : `content/rules/equilibrage.tres`.
- Formules : `core/balance/balance_model.gd`, testées dans `test/unit/core/balance/`.
- Mesures et écriture des valeurs : `tools/equilibrage.gd` (environ 2 min 30), qui produit aussi `docs/equilibrage-rapport.md`.
- Garde-fou : `test/unit/content/test_balance_content.gd` échoue si une valeur du contenu ne correspond plus aux formules.

```
godot --headless --path . -s tools/equilibrage.gd
```

## 1. Le joueur de référence (on mesure au lieu de deviner)

Pour savoir si un objectif est dur, il faut savoir combien un joueur marque. Le **joueur de référence**
(`core/balance/reference_player.gd`) joue des rounds complets avec le vrai code du jeu (détection des mains,
pipeline de score). À chaque main, il joue la meilleure combinaison de 5 cartes parmi ses 8, sans jamais défausser.

- C'est un joueur **honnête mais pas malin**. Il connaît le score de chaque combinaison, mais ne défausse pas
  et ne prépare rien. Un vrai joueur fait mieux grâce aux défausses : c'est sa marge.
- On simule 2 000 mains (500 rounds). L'erreur d'une moyenne baisse en 1/√n : 4 fois plus de mains
  donnent une mesure 2 fois plus précise.
- La graine est fixe : mêmes mesures à chaque lancement (vérifié).

**La méthode s'appelle Monte-Carlo** : quand une probabilité est trop compliquée à calculer à la main
(ici, « quel score fait-on avec 8 cartes tirées au hasard ? »), on la fait jouer des milliers de fois et on regarde les moyennes.

## 2. La valeur d'un objet : son gain moyen

> gain(objet) = E[score avec l'objet] / E[score sans] − 1

`E[...]` se lit « espérance », c'est-à-dire la moyenne sur beaucoup de parties. Un gain de 0,26 veut dire
« +26 % de score en moyenne ». C'est l'**unité commune** de tout l'équilibrage : un artefact, un manuel, un niveau de
main se comparent tous en « % de score ».

- **Nombres aléatoires communs** : avec et sans l'objet, le joueur reçoit exactement les mêmes cartes.
  La différence vient donc de l'objet, pas de la chance. C'est comme comparer deux médicaments sur les mêmes patients.
- Avantage : un nouveau type d'effet n'a besoin d'**aucune nouvelle formule**. La simulation mesure ce qu'il apporte,
  quel que soit son déclencheur, sa condition ou sa probabilité.

Exemple que la mesure a révélé : la Gourde d'élixir à +4 Compréhension faisait **+120 %**. La Compréhension de base
d'une main vaut environ 3, donc +4 la double. Elle est passée à +1, soit +30 %, comme les autres. De même, la Couronne
d'immortel (+1 par carte de rang 7 à 9) faisait +49 % : elle est passée à +0,5, soit +25 %.

## 3. Les prix : la courbe de coût

> prix = arrondi(gain / k), au moins `min_price`

C'est la **courbe de coût** de Schreiber et Romero (*Game Balance*) : tout ce qu'un objet apporte est ramené à une
seule unité, et le prix suit cette valeur. Un objet deux fois plus utile coûte deux fois plus cher.

`k` est la **valeur d'une pierre** : le gain de score qu'une pierre achète. On la déduit de l'**économie** :

> Π (1 + k × W_b) = `power_per_realm`  (2 : avec les pierres d'un royaume, le joueur double son score)

- `W_b` est le nombre de pierres gagnées au goulot b (voir section 5). Le produit `Π` porte sur les goulots du premier
  royaume. L'équation se résout par **dichotomie** : on essaie un `k`, on regarde si le produit est trop petit ou trop
  grand, et on coupe l'intervalle en deux, 60 fois.
- **Pourquoi l'économie et pas les objets ?** Une première version ancrait `k` sur le gain médian des artefacts. En
  ajoutant 13 artefacts plus faibles, la médiane a baissé : tous les prix ont gonflé (l'Épée de 6 à 10 pierres) et les
  objectifs se sont effondrés (le royaume 3 de 3 500 à 2 000). Ajouter du contenu ne doit pas changer la difficulté.
  Ancré sur l'économie, `k` ne bouge plus quand on ajoute des objets : seuls les nouveaux objets reçoivent un prix.
- Le même `k` sert aux manuels : une pierre achète toujours la même quantité de score, quel que soit l'objet.
  Un manuel de main rare coûte peu, parce que le joueur moyen la joue rarement. Un joueur qui construit son paquet
  autour de cette main en tire plus : c'est une récompense de la stratégie.

## 4. Les goulots d'un royaume

> multiplicateur = 1 + `bottleneck_step` × rang du goulot  →  ×1, ×1,5, ×2 (comme les blinds de Balatro)

> pierres = arrondi(`reward_base` + `reward_per_difficulty` × multiplicateur)  →  3, 4 et 5

Une récompense a une part fixe et une part **proportionnelle au risque** : un goulot deux fois plus dur rapporte plus.

## 5. Les objectifs : une exponentielle qui garde un pas d'avance

> score de base du royaume r = arrondi_2_chiffres( T1 × G^(r−1) ),  objectif = score de base × multiplicateur du goulot

**T1, le premier objectif** : le score d'un round que **90 % des joueurs de référence** atteignent
(`first_bottleneck_success = 0,9`). Statistiquement, c'est le quantile à 10 % : on trie les 500 rounds simulés et on
prend le 50e plus petit. Le premier goulot est réussi par presque tout le monde, sans objet ni défausse.

**G, la croissance d'un royaume au suivant** :

> G = π × Π (1 + k × W_b)

- `W_b` = pierres gagnées au goulot b : récompense, plus 1 pierre par main restante (le joueur de référence en garde 1),
  plus les intérêts de son épargne (10 pierres, soit 2 d'intérêt).
- `1 + k × W_b` est le facteur dont le joueur grandit en dépensant ces pierres. `Π` est le produit sur les goulots du royaume,
  qui vaut `power_per_realm` par construction (section 3) : G = π × 2 = 2,5 avec les réglages actuels.
- **π, la pression** (1,25) : la difficulté va 25 % plus vite que le joueur à chaque royaume. Sans elle, un joueur
  moyen resterait toujours pile au niveau. Avec elle, il doit jouer mieux que la moyenne (défausses, combos) pour suivre.

**Pourquoi une exponentielle ?** Les maths des jeux « idle » (Kongregate) le montrent : une exponentielle finit
toujours par dépasser une croissance plus lente. La puissance du joueur, elle, est limitée (5 emplacements d'artefact).
Une run reste donc tendue jusqu'au bout. C'est aussi ce qui rend le modèle **prolongeable** : un 4e, un 10e royaume
suivent la même courbe sans qu'on écrive un seul nombre.

`arrondi_2_chiffres` sert la lisibilité : 1 117 devient 1 100.

## 5 bis. Les mains : plus rare, plus fort

Une main rare doit rapporter plus, mais de combien ? On mesure d'abord sa **rareté exacte** `q` : la part des
tirages de 5 cartes du paquet qui la contiennent. L'outil énumère les 8 259 888 tirages possibles (5 cartes parmi
65) avec les vrais détecteurs du jeu : pas de hasard, pas d'estimation. Une main ajoutée ou un paquet changé est
remesuré tel quel.

La rareté devient une **surprise** (la quantité d'information de la théorie de Shannon, en nats) :

    s = -ln(q)

Une main toujours là (Souffle) a s = 0 ; chaque fois qu'une main est 10 fois plus rare, s monte de 2,3. La surprise
transforme des probabilités qui vont de 1 à 0,000 002 en une échelle de 0 à 13, lisible.

La **force** d'une main (Qi × Compréhension de base) suit la surprise :

    force = force_min × (1 + s)^δ,   avec δ = ln(force_max / force_min) / ln(1 + s_max)

- `force_min` (5) est la force de la main la plus commune, `force_max` (1 800) celle de la plus rare : ce sont les deux
  seuls choix de design, les autres mains s'étalent entre les deux.
- δ est calculé pour que la main la plus rare tombe pile sur `force_max`.
- Pourquoi pas `force ∝ 1 / q` ? Les Cinq Souverains sont 600 000 fois plus rares que le Souffle : une force
  proportionnelle écraserait toutes les mains du milieu. La puissance de la surprise garde l'ordre exact des raretés
  avec des écarts jouables.

La force se partage entre Qi et Compréhension :

    Compréhension = arrondi((force / force_min)^β),   Qi = arrondi(force / Compréhension)

β (`comprehension_exponent`, 0,4) dit quelle part de la force passe dans le multiplicateur : les mains rares ont plus
de Compréhension, comme dans Balatro. Un **niveau** ajoute `level_fraction` (30 %) de la base, en Qi et en
Compréhension. La **priorité** (quelle main gagne quand une combinaison en remplit plusieurs) suit l'ordre des forces ;
à rareté égale (Ascension pure et Cycle d'engendrement : 50 tirages chacune), l'ancienne priorité départage.

Le tableau des mains du rapport (`docs/equilibrage-rapport.md`) donne rareté, surprise et valeurs écrites.

## 6. Régler le jeu après des parties

| Ressenti | Paramètre (`equilibrage.tres`) | Effet |
| --- | --- | --- |
| Le début est trop dur ou trop facile | `first_bottleneck_success` (0,9) | 0,95 : plus facile, 0,8 : plus dur |
| La fin est trop dure ou trop facile | `pressure` (1,25) | 1,15 : plus doux, 1,4 : plus raide |
| Tout coûte trop cher ou pas assez | `power_per_realm` (2) | 2,5 : pierres plus précieuses, prix plus bas, mais objectifs plus raides |
| Pas assez de pierres | `reward_base`, `reward_per_difficulty` | récompenses des goulots |
| Les mains rares ne valent pas l'effort | `strongest_hand_strength` (1 800) | plus haut : toutes les mains rares montent |
| Les manuels sont trop ou pas assez forts | `level_fraction` (0,3) | part de la base ajoutée par niveau |

Après tout changement de paramètre, de main, de paquet ou d'objet : relancer l'outil, relire le rapport, lancer les tests.

## 7. Ajouter du contenu

- **Un royaume** : un `.tres` dans `content/realms/` avec son `order` et ses goulots. `base_score` peut rester à 0 ou être faux :
  l'outil l'écrit, le garde-fou vérifie.
- **Un artefact** : son `.tres` (effets, icône, textes). L'outil mesure son gain et écrit son prix.
- **Une main** : son `.tres` avec son détecteur. L'outil mesure sa rareté et écrit son Qi, sa Compréhension, ses gains
  de niveau et sa priorité, puis remesure objectifs et prix.

## 8. Limites connues (dites, pas cachées)

- Chaque objet est mesuré **seul** : les combos entre artefacts ne sont pas mesurés.
- Le joueur de référence ne défausse pas et n'achète rien pendant la mesure. La croissance du joueur entre les royaumes
  vient de la formule de G, pas d'une run simulée.
- Les pilules modifient le paquet : leur prix reste une donnée de `content/pills/`, hors modèle.
- La rareté des mains est mesurée sur 5 cartes tirées au hasard, pas sur la main de 8 avec défausses : l'ordre des
  mains est le même, mais une main qu'on peut « chasser » en défaussant (Pureté) est un peu plus facile en jeu.
- Les cartes ajoutent leur Qi à la main : il pèse plus dans une main commune que dans une main rare.

## Sources

- Ian Schreiber et Brenda Romero, *Game Balance* (CRC Press) : courbes de coût, mécaniques transitives.
- Anthony Pecorella, *The Math of Idle Games* (Kongregate, Game Developer) : croissance exponentielle contre polynomiale.
- Claude Shannon, *A Mathematical Theory of Communication* (1948) : l'information (surprise) d'un événement, -log(p).
- Blizzard, *Arena Balance Through Science* : équilibrer par simulation vers un taux de victoire visé.
- Balatro : objectifs ×1 / ×1,5 / ×2 dans une ante, croissance exponentielle d'une ante à l'autre.
