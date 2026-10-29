extends GutTest
## Zone defilante focusable : haut et bas la font defiler, aux bouts l'entree n'est pas prise.


func _action(name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	return event


func test_bas_fait_defiler_puis_laisse_passer_au_bout() -> void:
	var scroll: FocusScroll = add_child_autofree(FocusScroll.new())
	scroll.size = Vector2(100, 100)
	var content := Control.new()
	content.custom_minimum_size = Vector2(100, 130)
	scroll.add_child(content)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(scroll.focus_mode, Control.FOCUS_ALL)
	scroll._gui_input(_action(&"ui_down"))
	assert_gt(scroll.scroll_vertical, 0)
	scroll._gui_input(_action(&"ui_up"))
	assert_eq(scroll.scroll_vertical, 0)
