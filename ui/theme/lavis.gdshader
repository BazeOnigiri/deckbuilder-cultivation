shader_type canvas_item;
// Fond : encre qui se diffuse lentement sur le bleu nuit.
// Bruit fractal deforme par lui-meme (domain warping), ce qui donne des volutes plutot que des taches.

#include "res://ui/theme/bruit.gdshaderinc"

uniform vec4 base_color : source_color;
uniform vec4 deep_color : source_color;
uniform vec4 ink_color : source_color;
// Palette precedente : blend de 0 a 1 la remplace par taches d'encre qui s'etendent (pose par l'autoload Ambiance).
uniform vec4 old_base_color : source_color;
uniform vec4 old_deep_color : source_color;
uniform vec4 old_ink_color : source_color;
uniform float blend : hint_range(0.0, 1.0) = 1.0;
// Nombre d'unites de bruit sur la hauteur de l'ecran : plus grand = volutes plus petites.
uniform float scale = 2.5;
uniform float speed = 0.02;
uniform float warp = 1.5;
// Derive des volutes, en unites de bruit par unite de temps : sans elle, la deformation ne deplace l'encre
// que d'au plus `warp` et les grandes taches restent toujours du meme cote de l'ecran.
uniform vec2 drift = vec2(1.0, 0.4);
uniform float strength : hint_range(0.0, 1.0) = 0.7;
// Reglage « reduire les animations » : 0 fige le lavis (pose par main, declare dans project.godot).
global uniform float motion_scale;
// Teinte passagere de l'encre a la couleur de l'element joue (posee par la sequence de score).
global uniform vec4 pulse_color : source_color;
global uniform float pulse_strength;

vec3 palette(vec3 base, vec3 deep, vec3 ink, vec2 q, float f) {
	vec3 color = mix(base, deep, smoothstep(0.3, 0.7, q.y));
	float wash = smoothstep(0.35, 0.75, f);
	color = mix(color, ink, wash * strength);
	color = mix(color, pulse_color.rgb, wash * pulse_strength);
	// Aureole plus sombre au bord des lavis, comme l'encre qui seche sur le papier.
	float edge = 1.0 - smoothstep(0.0, 0.03, abs(f - 0.55));
	return mix(color, deep, edge * strength * 0.6);
}

void fragment() {
	// Coordonnees en hauteurs d'ecran : meme rendu quel que soit le format de la fenetre.
	vec2 p = FRAGCOORD.xy * SCREEN_PIXEL_SIZE.y * scale;
	float t = TIME * speed * motion_scale;
	vec2 q = vec2(fbm(p + vec2(0.0, t)), fbm(p + vec2(5.2, 1.3) - t));
	vec2 r = vec2(fbm(p + warp * q + vec2(1.7, 9.2) + t), fbm(p + warp * q + vec2(8.3, 2.8) - t));
	float f = fbm(p + warp * r + drift * t);
	vec3 color = palette(base_color.rgb, deep_color.rgb, ink_color.rgb, q, f);
	if (blend < 1.0) {
		// Grosses taches lentes : la nouvelle encre gagne d'abord les creux du bruit.
		float spread = fbm(p * 0.6 + vec2(3.1, 7.4));
		float reach = blend * 1.4 - 0.2;
		float mask = smoothstep(spread - 0.06, spread + 0.06, reach);
		color = mix(palette(old_base_color.rgb, old_deep_color.rgb, old_ink_color.rgb, q, f), color, mask);
	}
	COLOR = vec4(color, 1.0);
}
