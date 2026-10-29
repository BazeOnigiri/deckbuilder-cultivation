# Changelog

Toutes les modifications notables de ce projet sont documentées ici.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versions selon [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

### Ajouté

- Deblocages : une partie du contenu (12 artefacts, 4 pilules, 3 heritages, 1 sceau) est verrouillee au depart et s'ouvre par une condition de profil (gagner N parties, atteindre un royaume, jouer N fois une main, acheter N artefacts, vaincre N tribulations...). Verrous en donnees dans content/unlocks/ (UnlockRule + UnlockCondition), sans toucher aux definitions ni a l'empreinte d'equilibrage. La boutique et les sceaux-tresor ne tirent que le contenu debloque (meme profil et meme graine : meme boutique). Le compendium montre la condition d'un contenu verrouille ; le bilan de fin de partie liste les deblocages gagnes.
- Succes : 19 succes en donnees (content/achievements/), evalues pendant la partie et sur le profil (jouer un Cycle d'engendrement, gagner sans acheter d'artefact, franchir un goulot en une main, posseder 5 artefacts...). Rouleau « Succes » depuis les Statistiques (obtenus / total), notification discrete en jeu et liste dans le bilan. Profil en version 3 (anciens profils migres, champs unlocked et achievements optionnels).
- Aide « Comment jouer » en rouleau : but de la partie, jouer et defausser, score, mains, cycle d'engendrement, pierres et interets, boutique, tribulations. Les nombres sont lus dans le contenu. Ouverte depuis le bouton du menu principal et depuis l'onglet Aide de la Voie de cultivation ; proposee une seule fois a la toute premiere partie (champ optionnel help_offered du profil).
- Menu debug (F12, action debug_menu), reserve aux builds de developpement : +10 pierres, donner un artefact, une pilule, un manuel ou un heritage, ouvrir un sceau-tresor, gagner le goulot en cours, sauter a un royaume et un goulot. Logique dans core/debug/debug_actions.gd, testee. Pas de seed affichee dans le jeu : rien a changer de ce cote.
- Compendium depuis le menu principal : un rouleau a onglets (artefacts avec rarete, pilules, manuels, heritages, sceaux-tresor, tribulations), chaque entree en emplacement avec infobulle (nom, description, prix). Un contenu jamais offert en boutique ni possede reste une silhouette, avec un compteur « vus x / total » par onglet.
- Historique des parties : le profil garde les dernieres parties (nombre dans content/rules/profil_base.tres) avec date, resultat, royaume et goulot atteints, meilleur coup, main favorite, artefacts et heritages finaux, graine. Rouleau « Historique » depuis les Statistiques.
- Statistiques par contenu : artefacts les plus achetes (top 5) et taux de reussite de chaque tribulation, dans les Statistiques. Profil en version 2 (anciens profils migres, champs optionnels).
- Bilan de fin de partie enrichi : royaume atteint, meilleur coup avec le nom de sa main, graine, artefacts et heritages finaux en emplacements.
- La run retient la graine de sa RNG et la main de son meilleur coup (sauvegardes anciennes toujours lisibles).

- Choix de la langue (francais ou anglais) dans les Options : par defaut la langue du systeme si elle est proposee, sinon l'anglais. Appliquee au demarrage et a chaud, sauvegardee avec les reglages (les anciens fichiers restent valides).
- Mode contraste eleve dans les Options : couleurs de Qi, de Comprehension, de tribulation et textes secondaires renforces par un Theme de surcharge (ui/theme/contraste.tres).
- Vente des pilules, en round comme en boutique : S sur la pilule sous la souris montre le sceau « Vendre (n) », S une seconde fois (ou un clic sur le sceau) la vend pour la moitie de son prix arrondie en dessous. Un clic sur une pilule l'utilise toujours.
- Heritages possedes en emplacements avec infobulle (nom et description) dans l'onglet Run de la Voie de cultivation et dans le rouleau de la partie sauvegardee du menu.
- Infobulle sur les cartes d'un sceau de disciples (rang, element, Qi) et sur le compteur de pierres de la colonne laterale.
- Icone originale (cinq elements en pentagone dans un cercle dore) a la place du logo Godot, icon.ico pour l'exe Windows (applique seulement avec rcedit et modify_resources). Titre de fenetre et d'onglet « 五行 Wu Xing » (config/name inchange pour garder les sauvegardes), config/version.
- Credits : composants tiers du moteur et leurs licences, textes des licences OFL des polices, ligne des sons, declaration d'usage d'IA corrigee (code, SVG, shaders, sons, textes). README.md et LICENSE (code MIT, assets tous droits reserves).
- Jeu entier au clavier seul et a la manette : focus natif sur les cartes, objets, boutons, offres, sceaux-tresors et rouleaux (fleches ou croix et stick gauche), lueur or et jade de l'element vise, focus initial a l'ouverture de chaque ecran et rouleau. Espace ou A valide (selectionne une carte, utilise une pilule, achete), Entree reste « Jouer », S ou RB vend l'objet vise, l'infobulle suit le focus.
- Manette : A valider, B fermer ou deselectionner, X defausser, Y jouer, LT et RT trier, LB paquet, RB vendre, Select voie de cultivation, Start options (O au clavier). Les aides nomment les boutons quand une manette est branchee.
- Touches reconfigurables dans Options > Touches : cliquer puis appuyer sur la nouvelle touche ; une touche d'une autre action est echangee, une touche reservee (Echap, Espace, fleches, chiffres) refusee ; bouton « Touches par defaut ». Sauvegardees avec les reglages (anciens fichiers valides).
- Tactile : un appui long sur une carte ou un objet montre son infobulle sans cliquer, et propose la vente d'un artefact ou d'une pilule (sceau « Vendre »).
- Ameliorations de carte (une par carte), en donnees dans content/enhancements : vigueur (+30 Qi), esprit (+4 Comprehension), tresor (+2 pierres), jade (x2 Comprehension, 1 chance sur 4 de se briser, RNG de la run), fer noir (x1,5 Comprehension gardee en main), chaos originel (compte pour les cinq elements dans la Purete, l'Harmonie, les Ascensions et le Cycle) et roc (sans rang, 50 Qi, compte toujours sans former de combinaison).
- Auras (lueur) cumulables avec une amelioration, dans content/editions : brume (+30 Qi), aurore (+6 Comprehension), cinq couleurs (x1,5 Comprehension). Brume, cinq couleurs et vide (ne prend pas d'emplacement) vont aussi sur les artefacts, rarement proposes en boutique avec un supplement de prix (chance dans boutique_base.tres, poids dans chaque aura).
- Talismans de carte, dans content/talismans : echo (la carte compte deux fois, artefacts compris), fortune (+3 pierres gardee en main a la fin du goulot), alchimie (cree une pilule quand defaussee), eveil (la main jouee monte d'un niveau quand la carte compte).
- 14 pilules qui posent une amelioration, une aura ou un talisman ; le Rouleau de disciples propose parfois des cartes ameliorees (chances dans sceau_disciples.tres).
- Cartes dessinees avec leur amelioration (fond teinte et caractere en filigrane), leur aura (reflet anime, fige par Reduire les animations) et leur talisman (cachet a gauche), decrits dans l'infobulle ; liseret et badge de l'aura sur un artefact.
- Sauvegarde en version 2 (ameliorations, auras, talismans, auras d'artefact) avec migration : les sauvegardes precedentes restent valides.
- Rouleau Nouvelle partie : graine saisissable (texte, sans casse) ou tiree au hasard, affichee dans la Voie de cultivation et le bilan de fin ; meme graine et memes options donnent la meme partie.
- Partie du jour : graine tiree de la date UTC, la meme pour tous ce jour-la, indiquee comme telle.
- Tribulations tirees au hasard dans le pool des tribulations a chaque partie (sans doublon, sauvegardees, listees dans l'onglet Parcours), ou dans l'ordre classique en option.
- Mode sans fin : apres la victoire au dernier royaume, « Continuer sans fin » ajoute des royaumes celestes generes (objectifs par la formule de croissance de l'equilibrage, tribulation tiree). Meilleur royaume celeste au profil.
- Huit niveaux de difficulte (content/difficulties) aux modificateurs cumules : mains, defausses, objectifs (nouvelle regle target_percent), interets, relance. Gagner au niveau N ouvre le niveau N+1.
- Cinq defis (content/challenges) : Ermite des cimes, Deux souffles (paquet feu et eau), Lame unique, Heritier du clan, Graine du destin. Defis gagnes notes au profil.

### Corrigé

- Textes en dur passes dans les traductions : signe x des mains, Niveau, Objectif, pourcentage de victoires, vitesse x1,5 (virgule en francais), touches citees par l'aide (lues dans l'InputMap). Cle UI_STONES inutilisee supprimee.
- Vocabulaire : « partie » partout en francais, titre du rouleau de run aligne sur « Voie de cultivation », formulations anglaises de la pilule de la roue et de la tribulation du vent noir.
- Plein ecran en web : applique seulement au clic sur la case (jamais au demarrage), et la case se decoche si le navigateur refuse ou si on quitte avec Echap.
- Boutique : six etoffes (heritage Etal comprise) tiennent en 1152 px de large, le sceau Relancer passe sous les offres.
- Niveau d'une main au-dela de 9 : le nombre s'affiche apres les pastilles.
- La meteo des ambiances (escarbilles, volutes, poussiere) couvre toute la largeur reelle de la fenetre, pas seulement 1152x648.
- Les statistiques deroulent leur rouleau d'un coup avec « Reduire les animations ».
- Largeurs, marges, separations et durees de la colonne laterale, du menu, de la Voie de cultivation et de l'ecran de round deplacees dans le Theme et score_feel.tres.
- Heritage qui baisse la relance (Marche celeste) : la relance de la boutique en cours baisse tout de suite, plus seulement a la suivante.
- Pilule de dedoublement : la copie est glissee a une place tiree de la pioche (RNG de la run), et non plus piochee tout de suite.
- Profil : les statistiques sont ecrites apres chaque main jouee, plus seulement en fin de goulot.
- Sauvegarde : une version illisible est refusee sans planter, un rang relu est plafonne au Souverain, une carte a l'uid en double garde un uid neuf au lieu d'en ecraser une autre. Une vraie sauvegarde v1.0.0 est testee.
- Artefacts : une condition de main ne plante plus sur un declencheur sans main (defausse, goulot franchi), et la validation refuse ces combinaisons ainsi que des pierres sur un declencheur de main.
- Boutique : plus de relance pendant qu'un sceau est ouvert, et la relance ne propose plus un artefact deja dans les choix du sceau.
- Heritages : un modificateur sur une propriete decimale (ex : sell_fraction) garde sa partie decimale.
- Description de la pilule de fusion : le rang est plafonne au Souverain.
- Les sinogrammes des badges de rarete (凡 灵 神) s'affichent : ils sont ajoutes a la police des sceaux, qui sert de police de secours aux polices Noto Serif. Un test verifie que chaque sinogramme de textes.csv y figure.
- .gutconfig.json exclu de l'export, licences OFL incluses dans l'export.

## [1.1.0] - 2026-10-28

### Ajouté

- Neuf pilules (13 au total) : regression 退 (-1 rang), foret 林, montagne 岳 et lame 锋 (Bois, Terre, Metal), roue 轮 (chaque carte prend l'element que le sien engendre), dedoublement 分 (copie une carte dans le paquet), fusion 合 (2 cartes : la plus haute prend le rang de l'autre, qui est detruite), dissolution 散 (detruit jusqu'a 2 cartes, +2 pierres chacune), illumination 明 (la main formee par les cartes monte d'un niveau). Nouveaux effets en donnees ; un effet de pilule recoit maintenant la run.
- Six artefacts d'un nouveau genre (36 au total) : Arbre a sapeques (+3 pierres par goulot), Crapaud de jade (+1 pierre par main restante), Balai de bambou (+1 pierre par carte Bois defaussee), et trois artefacts qui grandissent pendant la run : Bambou celeste (+4 Qi par Paire jouee), Pierre d'eveil (+0,05 x Comprehension par carte defaussee), Arbre millenaire (+0,25 Comprehension par goulot franchi). Nouveaux declencheurs en donnees (goulot franchi, carte defaussee, crans), crans sauvegardes et rappeles dans l'infobulle. L'equilibrage compte les pierres d'un artefact dans son prix.
- Douze nouveaux artefacts (30 au total), avec icone SVG et sceau : Racine de ginseng, Sceau de jade, Lanterne d'esprit et Source cachee (cartes gardees en main), Eventail du vent, Cloche de bronze, Boussole geomantique, Pinceau de calligraphe, Montagne sacree, Hache de l'immortel, Grue celeste, Nuage pourpre. Nouveau declencheur en donnees : une carte gardee en main quand une main est jouee. Prix et raretes mesures par l'equilibrage.
- Huit royaumes : Ame naissante, Transformation divine, Raffinement du vide, Integration et Grande Ascension apres le Noyau d'or, objectifs prolonges par la formule de l'equilibrage. Cinq nouvelles tribulations : foudre pourpre (4 cartes au plus), gel eternel (Qi des cartes divise par deux), neant (figures scellees), chaines du karma (chaque defausse coute une main), mille epees (cartes Metal scellees). Chacune a son ambiance (palette, meteo) et son arrangement du theme musical.
- Heritages 传承 (les bons de Balatro) : un par royaume en boutique, ameliorations permanentes de la run en 4 paires (base puis amelioration) : +1 main par round, +1 defausse, +1 emplacement d'artefact, +1 offre en boutique puis relance moins chere. Chaque heritage est une liste de modificateurs de regles en donnees (content/legacies/) : le round, la boutique et l'economie lisent les regles effectives. Heritages possedes dans l'onglet Run de la Voie de cultivation.
- Sceaux-tresor (les paquets de Balatro) : 2 par visite de boutique, en plus des offres, et la relance ne les change pas. Bibliotheque 书 (1 manuel parmi 3, appris tout de suite), Coffret d'alchimiste 丹 (1 pilule parmi 3), Cage aux betes 兽 (1 artefact parmi 2, tire selon sa rarete), Rouleau de disciples 徒 (1 carte parmi 3 ajoutee au paquet). Le sceau s'ouvre dans un rouleau ; le fermer passe le reste. Un sceau ouvert est sauvegarde avec ses choix. Prix en donnees (content/packs/).
- Boutique aleatoire : au lieu de toujours 2 artefacts, 1 manuel et 1 pilule, chacun des 2 emplacements tire un type d'offre (artefact 70 %, manuel 15 %, pilule 15 %, poids dans content/rules/boutique_base.tres), puis un objet de ce type. Un type sans objet a proposer laisse sa place aux autres.
- Vente des artefacts, en round comme en boutique : un clic sur un artefact montre le sceau « Vendre (n) », un second clic le vend pour la moitie de son prix arrondie en dessous (sell_fraction dans content/rules/economie_base.tres). Au clavier : S deux fois sur l'artefact sous la souris.
- Raretes des artefacts : Mortel 凡, Spirituel 灵, Celeste 仙, Divin 神. L'equilibrage les deduit du gain mesure (un artefact fort est rare, parts dans content/rules/equilibrage.tres), la boutique tire une rarete selon ses poids (70 / 22 / 7 / 1 %) puis un artefact. Badge de rarete dans l'infobulle, couleurs dans le Theme.

### Corrigé

- Description de la pilule de raffinement : le rang monte jusqu'au Souverain, et non plus 9 au maximum.

## [1.0.0] - 2026-10-28

### Ajouté

- Premiere version complete : 3 royaumes, 12 mains, 18 artefacts, manuels et pilules, sons et musique, jouable au clavier et a la souris.
- Builds jointes a la release GitHub : export web (zip) et Windows (exe autonome). Preset d'export Windows.

### Corrigé

- Options ouvertes pendant une run : les touches (jouer, defausser...) n'agissent plus sur la run cachee sous le voile.
- Mesures d'equilibrage perimees detectees : l'outil note une empreinte du contenu mesure (paquet, mains, objets, royaumes, regles), un test echoue si le contenu a change sans relancer l'outil.
- Sauvegarde : la boutique et le round en cours passent eux aussi par la migration de version, pas seulement la run.
- Pilule de raffinement : son plafond suit le rang le plus haut du paquet (RankRules) au lieu d'une copie du 14 ; un test verifie que les autres copies (Ascension, Couronne d'immortel) suivent ce rang.
- Code en double fusionne : liste d'IDs pour la sauvegarde (SaveData.ids) et petites cartes de la vue du paquet et des exemples de mains (CardView.small).
- Rarete des mains environ 5 fois plus rapide : la rotation des elements ne change aucune main, l'outil ne compte qu'un tirage sur cinq avec un poids exact. Un test compare au comptage complet.
- Rapport d'equilibrage : la surprise du Souffle s'affiche 0.00 et non -0.00.

## [0.5.0] - 2026-10-28

### Ajouté

- Equilibrage par formules (docs/equilibrage.md) : un joueur de reference simule (Monte-Carlo, graine fixe) mesure le score d'un round et le gain moyen de chaque artefact et manuel. Prix = gain / valeur d'une pierre (courbe de cout ; la pierre se deduit de l'economie : les pierres d'un royaume doublent la puissance du joueur, donc ajouter des objets ne change pas la difficulte), recompenses et multiplicateurs des goulots par formule, objectifs = score atteint par 90 % des joueurs au depart, puis croissance exponentielle par royaume (puissance achetee par le joueur x pression). Un nouveau royaume n'a besoin que de son ordre. Parametres dans content/rules/equilibrage.tres, outil tools/equilibrage.gd, rapport docs/equilibrage-rapport.md, et un test qui detecte toute valeur qui ne suit plus les formules.
- Figures : le paquet passe a 70 cartes (rangs 1 a 14). Les chiffres vont de 1 a 10, Disciple, Maitre et Immortel deviennent les rangs 11 a 13, nouveau Souverain du Dao au rang 14, avec leur sinogramme dans le coin (徒 师 仙 尊). Points dessines pour les rangs 7 a 10. Comme Balatro, une figure rapporte 10 Qi et le Souverain 11 (content/rules/rangs.tres) ; le Souverain compte aussi sous le 1 dans une Ascension, sans boucle.
- Mains calculees par leur rarete (docs/equilibrage.md, section 5 bis) : l'outil compte exactement les 8 259 888 tirages de 5 cartes du paquet, la surprise -ln(rarete) donne la force de chaque main (Qi x Comprehension) entre 5 (Souffle) et 1800 (Cinq Souverains), partagee entre Qi et Comprehension ; gains de niveau (30 % de la base) et priorites en decoulent. Garde-fou : une main dont les valeurs ne suivent plus la formule fait echouer les tests.
- Manuels de technique en livres cousus a la chinoise, dessines par le moteur (ManualCover) : reliure a droite, fil qui passe par quatre trous et fait le tour du dos, tranche des pages, etiquette de titre avec un sinogramme propre a chaque main (息 双 偶 和 三 升 满 纯 四 登 生 尊), couleur de couverture selon la rarete de la main et motif (nuages, vagues, treillis, sapeques) : les douze livres sont tous differents. Couleurs et tailles dans le Theme (type ManualCover).
- Voie de cultivation : chaque main montre un exemple en petites cartes, comme Balatro ; les cartes qui comptent sont en pleine couleur, les autres pales. Exemples en donnees dans chaque main (HandDefinition.example), un test verifie que chacun est reconnu comme sa propre main.
- Infobulles facon Balatro (InfoBubble) : nom en titre, description sur un encart papier ou les valeurs de Qi sont en jade, celles de Comprehension en or et les elements dans leur couleur, puis un badge (Artefact, Manuel de technique dans la couleur de son livre, Pilule, ou l'element d'une carte). Les cartes montrent leur rang ou leur figure et le Qi qu'elles rapportent. Elles apparaissent plus vite (0,15 s).
- Jouer au clavier et a la souris (actions de l'InputMap, touches physiques donc meme place en AZERTY et QWERTY) : 1 a 8 choisissent une carte, Entree joue la main ou continue apres la boutique, D defausse, Retour arriere ou clic droit deselectionnent tout, R et E trient, Tab montre le paquet, V ouvre la Voie de cultivation, Echap ferme un rouleau. Un rouleau ouvert garde les touches pour lui. Touches rappelees dans l'infobulle des boutons et dans un onglet Touches de la Voie de cultivation.

### Modifié

- Objectifs recalcules (paquet de 70 cartes, mains par rarete) : 460 / 690 / 920 au premier royaume (avant 200 / 300 / 400), 1200 au deuxieme, 2900 au troisieme. Prix des artefacts et des manuels selon leur gain mesure (manuels de 1 a 10 pierres).
- Treize nouveaux artefacts (18 au total) avec leur icone SVG et leur sceau : les quatre betes celestes et le qilin (un par element : Dragon azur, Oiseau vermillon, Qilin, Tigre blanc, Tortue noire), Pagode des trois sages, Echelle celeste, Banniere des cinq vents, Bassin de purete, Grain de riz spirituel, Couronne d'immortel, Ermite et Chaudron alchimique. Deux nouvelles conditions en donnees : rang de la carte et nombre de cartes qui comptent. Prix mesures par l'equilibrage (1 a 8 pierres).
- Couronne d'immortel : bonus pour chaque figure qui compte (rangs 11 a 14) au lieu des rangs 7 a 9. Pilule de raffinement : monte jusqu'au Souverain.
- Gourde d'elixir : +1 Comprehension au lieu de +4 (la mesure donnait +120 % de score, quatre fois les autres artefacts).

### Corrigé

- Boutique plus large que l'ecran : les noms d'offres passent a la ligne dans une largeur fixe (Theme, ShopCloth/title_width) et le message de niveau suit la largeur des offres.
- Rouleaux (Voie de cultivation, regles...) : la molette en bas de la liste fermait le rouleau. Seuls les clics gauche et droit hors du rouleau le ferment.

## [0.4.0] - 2026-10-27

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
- Barre d'actions : tri de la main par rang ou par element (la selection est gardee), bouton « Jouer la main » mis en avant en or, pioche dessinee (dos de carte au sceau 道) avec le nombre de cartes restantes sur le paquet.
- Annonce de la main : au debut de la sequence de score, son nom tombe en grand sur un sceau rouge, puis le tableau le reprend. Quand le total tombe, le ciel s'eclaire un instant, d'autant plus que le coup est fort (coupe par « Reduire les animations »).
- Tribulations : une carte que la tribulation empeche de compter (ex. le feu scelle) brule doucement par le bas et porte le sceau 封, le rang reste lisible. Le bandeau de la tribulation scintille dans la colonne. Les noms longs de goulot passent a la ligne.
- Fin de goulot : a la victoire, le sceau 破 tombe au centre et une onde de choc doree part, des cristaux de pierres tombent sur le compteur qui saute, puis la boutique s'ouvre. A l'echec, des fissures de feu s'ouvrent et l'encre noire envahit l'ecran, avec le message d'echec et un bouton vers le menu. Rythme dans ui/round/round_end_feel.tres.
- Boutique vivante : les offres sont des emplacements (artefacts, manuels 法, pilules) avec nom et prix en pierres, qui se retournent a l'ouverture et a la relance. Un achat file vers son emplacement de la rangee haute. Un manuel affiche le gain de niveau de la main. La main du round gagne laisse la place a la boutique. Une pilule utilisee fait briller la carte de la couleur de son element.
- Sequence de score sans texte au-dessus des cartes : le nom de la main et le compteur Qi x Comprehension defilent dans la colonne, d'ou le total s'envole vers le Qi du round.
- Meditant a la place de l'anneau d'objectif : la silhouette en tailleur se remplit de qi de bas en haut avec le score du round, une aura pulse quand l'objectif est atteint.
- Icones dessinees : pierre spirituelle (colonne, prix de la boutique, cristaux qui tombent a la victoire) et un dessin par artefact a la place de son caractere. Un artefact = son .tres + son SVG dans content/artifacts/icones/.
- Vue du paquet : un clic sur la pioche montre les 45 cartes de la run, une rangee par element triee par rang, avec le compte de cartes encore a piocher. Les cartes en main, jouees ou defaussees sont grisees. Un clic ou Echap ferme la vue.
- Ambiance par ecran : chaque tribulation a son fond et sa meteo (braise et escarbilles pour les flammes, encre grise et trainees de poussiere pour le vent noir, pourpre et vignette qui respire pour le demon interieur), la boutique a un lavis chaud, le menu et les goulots simples gardent la nuit. Fondu entre deux ambiances, meteo coupee par « Reduire les animations ». Une ambiance = un .tres dans ui/ambiances/ avec l'id du goulot.
- Boutique en pavillon : cadre laque rouge a double filet d'or et coins ornes, enseigne calligraphiee 坊市 entre deux lanternes qui se balancent, offres posees sur des etoffes avec une etiquette de prix et l'icone de pierre, bouton Relancer en sceau rouge. Police des sceaux etendue a 17 caracteres.
- Fin de goulot plus marquee : deux ondes dorees, le ciel s'eclaire et le lavis se teinte d'or. Le passage d'une ambiance a l'autre se fait par taches d'encre qui s'etendent. Plus de texte de victoire dans la boutique (les cristaux montrent le gain).
- Tribulations bien distinctes : chaque ambiance regle aussi la forme du lavis (taille, deformation, force) et la couleur du bord de l'ecran. Flammes : brasier en bas, braises et etincelles. Vent noir : encre grise qui tourbillonne vite, rafales sombres, trainees et debris. Demon interieur : grandes ombres, brume pourpre, bord cramoisi qui bat, braises qui tombent.
- Options completes : vitesse de jeu (x1 a x3), plein ecran, et pendant une run : retour au menu (la run reste a continuer) et nouvelle partie (avec confirmation). Reglages sauvegardes.
- Score sans texte : la carte ou l'artefact qui se declenche s'allume (aura doree autour de l'artefact), une orbe de qi file vers la case Qi (jade) ou Comprehension (or) de la colonne, qui defile et s'eclaire a l'arrivee. Une multiplication envoie une orbe plus grosse et lache un anneau autour de la case. Plus de « +2 Qi » ni de nom d'artefact a l'ecran.
- Kit des menus « rouleaux et sceaux » : rouleau de papier de riz entre deux baguettes qui se deroule, rouleau ouvert par-dessus l'ecran (ferme au clic a cote, avec Echap ou par le sceau Fermer), choix a l'encre souligne d'un trait de pinceau au survol, boutons sceaux, interrupteurs de jade, listes et onglets en signets.
- Menu principal « 五行 Wu Xing » : rouleau suspendu avec le titre calligraphie et les choix a l'encre, lune aux nuages qui passent, meditant entoure des cinq phases qui tournent dans l'ordre du cycle d'engendrement. Nouvelle partie avec une run sauvegardee : un rouleau la resume (goulot, pierres, dessins des artefacts) et propose Continuer ou Abandonner et recommencer ; sans sauvegarde, la partie commence directement.
- Statistiques, options, credits, Voie de cultivation et fin de run en rouleaux : lignes a points de suite, interrupteurs et liste a l'encre, boutons de run et confirmation en sceaux, credits avec la licence de Godot, onglets en signets (mains, parcours avec le sceau 破 et les contraintes, run), bilan de la run sous le titre de victoire ou d'echec.
- Bouton « Quitter le jeu » dans le menu principal (cache dans l'export web).
- Voie de cultivation plus visuelle : une tablette de jade par main (pastilles de niveau, Qi et Comprehension en pilules), parcours en chemin vertical (meditant sur le goulot en cours, sceau 破 sur les goulots franchis), chiffres de la run en tuiles. Statistiques en tuiles, meilleur royaume en grand, barres d'encre des mains les plus jouees.
- Sons du jeu synthetises par tools/sons/generate_sounds.py a partir de recettes en donnees (recettes.json) : cordes pincees, gongs, cloches, souffles d'encre, cristaux. 17 sons dans audio/sfx, deterministes.
- Lecteur de sons (autoload Sons) : sons appeles par ID depuis des fiches SoundCue de content/sons/ (generees avec les sons), gamme pentatonique pour les notes, legere variation de hauteur, 12 voix. Bus Musique et Effets, curseurs Volume general, Musique et Effets sonores dans les Options (sauvegardes).
- Sons branches sur le jeu : clic et survol de tous les boutons, pioche, carte jouee, defausse, annonce de la main, une note par carte qui compte qui monte dans la gamme, orbes (depart, impact) et gong des multiplications, sceaux de tribulation, victoire, defaite, pierres, achats, manuels et pilules.
- Nappes d'ambiance generees par le meme script (bourdon, vent, notes pentatoniques, boucles de 24 s sans couture) : nuit, boutique, tribulation. Chaque ambiance choisit sa nappe (champ music), fondu croise au changement d'ecran.
- Sources sonores CC0 (Kenney Casino Audio et Impact Sounds, selection VCSL : Dan Tranh, percussions, cloches) : manifeste tools/sons/sources.json, telechargement par fetch_sources.py, conversion des .ogg par Godot (ogg_capture.gd puis split_capture.py). Rien de tout ca dans le depot ni dans l'export.
- Bruitages refaits a partir d'echantillons enregistres (papier et pions Kenney, cithare Dan Tranh, tambour, gong, verres, carillons VCSL) : sons courts et secs, pion de jade + note de cithare qui montent dans la gamme pentatonique a chaque carte qui compte, tambour et gong pour les multiplications, reverberation courte.
- Musique composee : theme lo-fi en sol# mineur pentatonique a 76 BPM, ecrit en donnees (tools/sons/partition.json : accords, basse, arpege et melodie au Dan Tranh, nappe chaude, percussions), grain cassette et reverberation, boucle de 16 mesures sans couture. Variantes nuit, boutique et tribulation jouees ensemble (AudioStreamSynchronized) : changer d'ecran fait un fondu a puissance constante sans que la musique reprenne au debut.
- Huit arrangements du theme au lieu de trois : menu principal, rounds, boutique, une par tribulation (demon : bourdon dissonant et tremolo grave ; flammes : tambours rapides et gong toutes les 4 mesures ; vent noir : glissandos de cithare et souffle), victoire et defaite sur le bilan de la run. Musique en 22 kHz (deja filtree sous 10 kHz) pour garder le poids des fichiers.
- Sons en plusieurs prises : clic, survol, pioche, carte jouee, defausse, decompte des cartes, orbes, multiplication, achat et sceau ont 2 a 6 enregistrements differents, tires au hasard sans jamais rejouer le meme deux fois de suite, avec une legere variation de hauteur et de volume. Prendre ou reposer une carte a son propre son (papier), distinct du clic des boutons.
- Skill de projet sons-et-musique (.claude/skills/) : principes du son de jeu, ce que fait Balatro, marche a suivre pour ajouter un son ou un arrangement.

### Corrigé

- Trait de pinceau des choix du menu trop long : il etait mesure sur la cle de traduction et non sur le texte affiche.
- Fond lavis : l'encre restait toujours du meme cote de l'ecran. Les volutes derivent maintenant lentement a travers tout l'ecran (parametre drift de ui/theme/lavis.tres).

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
