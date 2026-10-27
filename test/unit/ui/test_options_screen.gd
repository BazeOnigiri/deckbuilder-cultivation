extends GutTest
## Options : les curseurs de volume montrent le reglage et le modifient.

const SCREEN := preload("res://ui/options/options_screen.tscn")


func test_curseur_de_musique() -> void:
	var screen: Control = SCREEN.instantiate()
	screen.settings.music_volume = 0.25
	add_child_autofree(screen)
	var slider: HSlider = screen.get_node("%MusicVolume")
	assert_eq(slider.value, 0.25)
	watch_signals(screen)
	slider.value = 0.5
	assert_eq(screen.settings.music_volume, 0.5)
	assert_signal_emitted(screen, "settings_changed")
