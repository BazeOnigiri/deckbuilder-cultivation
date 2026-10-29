class_name ThirdPartyCredits
extends RefCounted
## Compose le texte des composants tiers du moteur (Engine.get_copyright_info) et de leurs licences
## (Engine.get_license_info). Les donnees sont passees en parametre pour tester sans moteur.


## Une ligne par composant avec ses licences, puis le texte complet de chaque licence citee.
static func build(copyrights: Array[Dictionary], licenses: Dictionary) -> String:
	var lines: Array[String] = []
	var used: Array[String] = []
	for component in copyrights:
		var names: Array[String] = []
		for part: Dictionary in component.get("parts", []):
			var license := str(part.get("license", ""))
			if license == "":
				continue
			if license not in names:
				names.append(license)
			if license not in used:
				used.append(license)
		lines.append("%s : %s" % [component.get("name", ""), ", ".join(names)])
	used.sort()
	var texts: Array[String] = []
	for license in used:
		if licenses.has(license):
			texts.append("%s\n\n%s" % [license, licenses[license]])
	return "\n".join(lines) + "\n\n" + "\n\n".join(texts)
