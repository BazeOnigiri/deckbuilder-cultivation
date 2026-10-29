class_name RunSetup
extends RefCounted
## Options d'une nouvelle partie (rouleau Nouvelle partie) : graine, partie du jour, difficulte, defi, tribulations.
## Meme graine et memes options : meme partie. Sauvegardees avec la run.

## Lettres des graines tirees : sans 0, O, 1 ni I, faciles a recopier.
const CODE_ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LENGTH := 8

## Graine en texte, telle qu'affichee. Vide : run d'avant les graines (ancienne sauvegarde), RNG non resemee.
var seed_text: String = ""
var daily: bool = false
var difficulty: int = 1
var challenge: ChallengeDefinition
## Faux : mode classique, chaque royaume garde sa tribulation du contenu.
var random_tribulations: bool = false


## Graine de la RNG de la run. Majuscules et espaces autour ignores : « wuxing » et « WUXING » donnent la meme.
static func seed_of(text: String) -> int:
	return normalized(text).hash()


static func normalized(text: String) -> String:
	return text.strip_edges().to_upper()


func seed_value() -> int:
	return seed_of(seed_text)


## Graine tiree au hasard, a recopier pour rejouer la meme partie.
static func random_code(rng: RandomNumberGenerator) -> String:
	var code := ""
	for i: int in CODE_LENGTH:
		code += CODE_ALPHABET[rng.randi_range(0, CODE_ALPHABET.length() - 1)]
	return code


## Graine de la partie du jour : la date UTC (AAAA-MM-JJ), la meme pour tous ce jour-la.
static func daily_code(unix_time: int) -> String:
	return Time.get_date_string_from_unix_time(unix_time)


static func for_daily(unix_time: int) -> RunSetup:
	var setup := RunSetup.new()
	setup.seed_text = daily_code(unix_time)
	setup.daily = true
	setup.random_tribulations = true
	return setup


## Choix du rouleau Nouvelle partie. Graine saisie vide : fallback_code (tiree au hasard).
static func custom(seed_input: String, level: int, random: bool, fallback_code: String) -> RunSetup:
	var setup := RunSetup.new()
	var typed := normalized(seed_input)
	setup.seed_text = typed if not typed.is_empty() else fallback_code
	setup.difficulty = maxi(1, level)
	setup.random_tribulations = random
	return setup


## fallback_code : graine si le defi n'en impose pas.
static func for_challenge(definition: ChallengeDefinition, fallback_code: String) -> RunSetup:
	var setup := RunSetup.new()
	setup.challenge = definition
	var imposed := normalized(definition.seed_text)
	setup.seed_text = imposed if not imposed.is_empty() else fallback_code
	setup.difficulty = definition.difficulty
	setup.random_tribulations = definition.random_tribulations
	return setup


func to_dict() -> Dictionary:
	return {"seed": seed_text, "daily": daily, "difficulty": difficulty,
		"challenge": "" if challenge == null else String(challenge.id), "random_tribulations": random_tribulations}


## Le fichier vient du disque du joueur : valeur absente ou de mauvais type, valeur par defaut. Defi retire : aucun.
static func from_dict(data: Variant, content: GameContent) -> RunSetup:
	var setup := RunSetup.new()
	if not data is Dictionary:
		return setup
	var saved: Dictionary = data
	setup.seed_text = saved["seed"] if saved.get("seed") is String else ""
	setup.daily = saved.get("daily") is bool and saved["daily"]
	setup.difficulty = maxi(1, SaveData.int_of(saved, "difficulty", 1))
	setup.challenge = content.challenge_by_id(StringName(str(saved.get("challenge", ""))))
	setup.random_tribulations = saved.get("random_tribulations") is bool and saved["random_tribulations"]
	return setup
