shader_type canvas_item;
// Onde de choc du goulot franchi : un anneau part du centre de l'ecran et s'efface en grandissant.
// progress pose par RoundEnd.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ring_color : source_color = vec4(0.788, 0.651, 0.353, 1.0);
// Centre en coordonnees d'ecran (0 a 1).
uniform vec2 center = vec2(0.5);
// Rayon maximal et epaisseur, en hauteurs d'ecran.
uniform float max_radius = 0.9;
uniform float width = 0.03;

void fragment() {
	vec2 uv = FRAGCOORD.xy * SCREEN_PIXEL_SIZE;
	// En hauteurs d'ecran : l'anneau reste rond quel que soit le format de la fenetre.
	vec2 p = (uv - center) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float ring = 1.0 - smoothstep(0.0, width, abs(length(p) - progress * max_radius));
	COLOR = vec4(ring_color.rgb, ring_color.a * ring * (1.0 - progress));
}
