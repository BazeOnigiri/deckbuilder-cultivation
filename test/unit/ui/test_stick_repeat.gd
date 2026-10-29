extends GutTest
## Delai de repetition du stick gauche : la direction repetee est ignoree avant le delai, le centre rearme.


func _motion(axis: int, value: float) -> InputEventJoypadMotion:
	var motion := InputEventJoypadMotion.new()
	motion.axis = axis
	motion.axis_value = value
	return motion


func test_repetition_ignoree_avant_le_delai() -> void:
	var repeat := StickRepeat.new(200)
	assert_true(repeat.allow(_motion(JOY_AXIS_LEFT_Y, 1.0), 1000))
	assert_false(repeat.allow(_motion(JOY_AXIS_LEFT_Y, 1.0), 1100))
	assert_true(repeat.allow(_motion(JOY_AXIS_LEFT_Y, 1.0), 1200))


func test_centre_rearme_et_autre_direction_libre() -> void:
	var repeat := StickRepeat.new(200)
	repeat.allow(_motion(JOY_AXIS_LEFT_Y, 1.0), 1000)
	assert_true(repeat.allow(_motion(JOY_AXIS_LEFT_Y, -1.0), 1010), "autre sens")
	assert_true(repeat.allow(_motion(JOY_AXIS_LEFT_X, 1.0), 1010), "autre axe")
	assert_true(repeat.allow(_motion(JOY_AXIS_LEFT_Y, 0.0), 1020))
	assert_true(repeat.allow(_motion(JOY_AXIS_LEFT_Y, 1.0), 1030), "apres le centre")


func test_le_reste_passe() -> void:
	var repeat := StickRepeat.new(200)
	assert_true(repeat.allow(InputEventKey.new(), 0))
	assert_true(repeat.allow(_motion(JOY_AXIS_RIGHT_Y, 1.0), 0))
	assert_true(repeat.allow(_motion(JOY_AXIS_RIGHT_Y, 1.0), 1))
