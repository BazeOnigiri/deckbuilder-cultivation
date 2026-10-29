class_name AchievementsList
extends RefCounted
## Contenu du rouleau « Succes » : obtenus / total, puis chaque succes avec son sceau (grise tant que non obtenu),
## son nom et ce qu'il demande.


static func build(profile: ProfileStats, content: GameContent) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(scroll.get_theme_constant(&"info_width", &"ScrollPanel"),
		scroll.get_theme_constant(&"tab_height", &"ScrollPanel"))
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var all := content.unlocks.achievements()
	var counter := SideColumn.make_label(&"ScrollCaption")
	counter.text = TranslationServer.translate("UI_ACHIEVEMENTS_COUNT") % [obtained_count(profile, all), all.size()]
	column.add_child(counter)
	for achievement: AchievementDefinition in all:
		column.add_child(_entry(achievement, profile.has_achievement(achievement.id)))
	return scroll


static func obtained_count(profile: ProfileStats, all: Array[AchievementDefinition]) -> int:
	return all.filter(func(achievement: AchievementDefinition) -> bool: return profile.has_achievement(achievement.id)).size()


static func _entry(achievement: AchievementDefinition, obtained: bool) -> HBoxContainer:
	var line := HBoxContainer.new()
	var slot := ItemSlot.new()
	slot.kind = ItemSlot.Kind.PILL
	slot.glyph = achievement.glyph
	slot.disabled = not obtained
	line.add_child(slot)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := SideColumn.make_label(&"ScrollText")
	title.text = TranslationServer.translate(achievement.name_key)
	text.add_child(title)
	var detail := SideColumn.make_label(&"ScrollCaption")
	detail.text = TranslationServer.translate(achievement.description_key)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(detail)
	line.add_child(text)
	return line
