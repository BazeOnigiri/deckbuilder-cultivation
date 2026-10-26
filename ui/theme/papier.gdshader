shader_type canvas_item;
// Papier de riz pose sur tout le jeu : grain, fibres et vignette. Fixe, le papier ne bouge pas.
// Ne lit pas l'ecran : on peint du clair et du sombre transparents par-dessus, moins couteux en web.

#include "res://ui/theme/bruit.gdshaderinc"

uniform float grain : hint_range(0.0, 0.2) = 0.05;
uniform float fibers : hint_range(0.0, 0.2) = 0.04;
// Nombre de fibres sur la hauteur de l'ecran.
uniform float fiber_scale = 6.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.45;
// Teinte du bord (posee par l'autoload Ambiance) : braise, pourpre...
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	// Grain au pixel physique, net quelle que soit la resolution.
	float g = (hash(FRAGCOORD.xy) - 0.5) * grain;
	// Bruit tres etire dans deux directions croisees, visible par plaques : des fibres, pas des lignes.
	vec2 p = FRAGCOORD.xy * SCREEN_PIXEL_SIZE.y * fiber_scale;
	const mat2 ROT_A = mat2(vec2(0.97, 0.26), vec2(-0.26, 0.97));
	const mat2 ROT_B = mat2(vec2(0.91, -0.42), vec2(0.42, 0.91));
	float strands = max(noise(ROT_A * p * vec2(1.5, 25.0)), noise(ROT_B * p * vec2(1.5, 25.0) + 31.0));
	float paper = g + (strands - 0.5) * noise(p * 0.7) * 2.0 * fibers;
	float shade = smoothstep(0.4, 1.0, length(SCREEN_UV - 0.5) * 1.4) * vignette;
	float light = max(paper, 0.0);
	float dark = max(-paper, 0.0);
	float alpha = clamp(light + dark + shade, 0.0, 1.0);
	COLOR = vec4((vec3(light) + vignette_color.rgb * shade) / max(alpha, 0.0001), alpha);
}
