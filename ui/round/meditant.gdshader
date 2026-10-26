shader_type canvas_item;
// Meditant de la colonne : le qi le remplit de bas en haut avec le score du round.
// Objectif atteint : une aura pulse autour de la silhouette. Texture = silhouette pleine (meditant.svg).

#include "res://ui/theme/bruit.gdshaderinc"

// Part de l'objectif atteinte, de 0 a 1. Posee par SideColumn.
uniform float fill : hint_range(0.0, 1.0) = 0.0;
uniform vec4 empty_color : source_color = vec4(0.17, 0.23, 0.27, 1.0);
uniform vec4 qi_color : source_color = vec4(0.79, 0.65, 0.35, 1.0);
uniform vec4 aura_color : source_color = vec4(0.79, 0.65, 0.35, 0.8);
// Hauteur des vagues de la surface du qi, en part de la hauteur.
uniform float wave = 0.04;
// Distance du halo autour de la silhouette, en part de la texture.
uniform float aura_size = 0.06;
uniform float aura_speed = 2.0;
// Reglage « reduire les animations » : 0 fige la surface et l'aura (declare dans project.godot).
global uniform float motion_scale;

void fragment() {
	float t = TIME * motion_scale;
	float mask = texture(TEXTURE, UV).a;
	// Surface du qi : ondule seulement entre vide et plein.
	float ripple = (fbm(vec2(UV.x * 6.0, t * 0.5)) - 0.5) * wave * step(0.001, fill) * step(fill, 0.999);
	float level = 1.0 - fill + ripple;
	float filled = smoothstep(level - 0.01, level + 0.01, UV.y);
	vec4 body = mix(empty_color, qi_color, filled);
	// Halo : la silhouette echantillonnee tout autour, la ou elle n'est pas.
	float halo = 0.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		halo += texture(TEXTURE, UV + vec2(cos(a), sin(a)) * aura_size).a;
	}
	halo = clamp(halo / 8.0, 0.0, 1.0) * (1.0 - mask);
	float lit = smoothstep(0.98, 1.0, fill) * (0.6 + 0.4 * sin(t * aura_speed));
	float aura = halo * lit * aura_color.a;
	COLOR = vec4(mix(aura_color.rgb, body.rgb, mask), max(mask * body.a, aura));
}
