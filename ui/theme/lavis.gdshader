shader_type canvas_item;
// Fond : encre qui se diffuse lentement sur le bleu nuit.
// Bruit fractal deforme par lui-meme (domain warping), ce qui donne des volutes plutot que des taches.

#include "res://ui/theme/bruit.gdshaderinc"

uniform vec4 base_color : source_color;
uniform vec4 deep_color : source_color;
uniform vec4 ink_color : source_color;
// Nombre d'unites de bruit sur la hauteur de l'ecran : plus grand = volutes plus petites.
uniform float scale = 2.5;
uniform float speed = 0.02;
uniform float warp = 1.5;
uniform float strength : hint_range(0.0, 1.0) = 0.7;
// Reglage « reduire les animations » : 0 fige le lavis (pose par main, declare dans project.godot).
global uniform float motion_scale;

void fragment() {
	// Coordonnees en hauteurs d'ecran : meme rendu quel que soit le format de la fenetre.
	vec2 p = FRAGCOORD.xy * SCREEN_PIXEL_SIZE.y * scale;
	float t = TIME * speed * motion_scale;
	vec2 q = vec2(fbm(p + vec2(0.0, t)), fbm(p + vec2(5.2, 1.3) - t));
	vec2 r = vec2(fbm(p + warp * q + vec2(1.7, 9.2) + t), fbm(p + warp * q + vec2(8.3, 2.8) - t));
	float f = fbm(p + warp * r);
	vec3 color = mix(base_color.rgb, deep_color.rgb, smoothstep(0.3, 0.7, q.y));
	color = mix(color, ink_color.rgb, smoothstep(0.35, 0.75, f) * strength);
	// Aureole plus sombre au bord des lavis, comme l'encre qui seche sur le papier.
	float edge = 1.0 - smoothstep(0.0, 0.03, abs(f - 0.55));
	color = mix(color, deep_color.rgb, edge * strength * 0.6);
	COLOR = vec4(color, 1.0);
}
