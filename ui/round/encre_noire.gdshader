shader_type canvas_item;
// Echec de la percee : des fissures de feu s'ouvrent, puis l'encre noire envahit l'ecran depuis les bords.
// progress pose par RoundEnd.

#include "res://ui/theme/bruit.gdshaderinc"

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink_color : source_color = vec4(0.012, 0.018, 0.024, 1.0);
uniform vec4 crack_color : source_color = vec4(0.95, 0.45, 0.15, 1.0);
// Nombre d'unites de bruit sur la hauteur de l'ecran.
uniform float scale = 3.0;
// Part de la sequence ou les fissures s'ouvrent avant que l'encre arrive.
uniform float crack_share = 0.4;
uniform float crack_width = 0.02;
// Frange dentelee de l'encre.
uniform float fringe = 0.4;

void fragment() {
	vec2 uv = FRAGCOORD.xy * SCREEN_PIXEL_SIZE;
	vec2 p = uv * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0) * scale;
	// Fissures : les lignes ou le bruit passe par sa valeur moyenne.
	float cracks = 1.0 - smoothstep(0.0, crack_width, abs(fbm(p) - 0.5));
	cracks *= smoothstep(0.0, crack_share, progress);
	// Encre : 0 au centre, environ 1 dans les coins ; le seuil descend avec progress.
	float edge = length(uv - 0.5) * 1.4 + (fbm(p * 1.7 + 3.0) - 0.5) * fringe;
	float spread = smoothstep(crack_share * 0.5, 1.0, progress);
	float ink = smoothstep(-0.03, 0.03, edge - (1.0 - spread * 1.3));
	COLOR = vec4(mix(crack_color.rgb, ink_color.rgb, ink), max(ink * ink_color.a, cracks));
}
