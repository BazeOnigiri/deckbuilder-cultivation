shader_type canvas_item;
// Fausse 3D : chaque sommet dessine par la carte (fond, traits, lettres, symboles) tourne autour du centre
// de la carte, puis est projete en perspective. Pas de texture intermediaire : le texte reste net.
// Dissolution : la carte se troue comme du papier qui brule, le bord prend la couleur de son element.

#include "res://ui/theme/bruit.gdshaderinc"

uniform vec2 card_size = vec2(92.0, 132.0);
// Rotation en radians autour de l'axe x (haut / bas) et de l'axe y (gauche / droite). Pose par HandView.
uniform vec2 tilt = vec2(0.0);
// Distance de l'oeil a la carte, en pixels : plus petite = perspective plus marquee.
uniform float eye_distance = 400.0;
// 0 = carte entiere, 1 = carte disparue. Pose par HandView quand la carte quitte la main.
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0);
// Largeur du bord colore, en part du bruit.
uniform float edge_width = 0.08;
// Taille des trous : nombre de motifs de bruit sur la largeur de la carte.
uniform float noise_scale = 5.0;

// Position sur la carte avant la perspective : les trous restent attaches a la carte quand elle s'incline.
varying vec2 local;

void vertex() {
	local = VERTEX / card_size;
	vec2 center = card_size * 0.5;
	vec3 p = vec3(VERTEX - center, 0.0);
	float cy = cos(tilt.y);
	float sy = sin(tilt.y);
	p = vec3(p.x * cy + p.z * sy, p.y, -p.x * sy + p.z * cy);
	float cx = cos(tilt.x);
	float sx = sin(tilt.x);
	p = vec3(p.x, p.y * cx - p.z * sx, p.y * sx + p.z * cx);
	// z positif = vers l'oeil : ce qui se rapproche grandit.
	VERTEX = center + p.xy * eye_distance / (eye_distance - p.z);
}

void fragment() {
	if (dissolve > 0.0) {
		float n = fbm(local * noise_scale);
		// Seuil etire pour qu'a dissolve = 1 il ne reste plus rien (le bruit reste sous 1).
		float threshold = dissolve * (1.0 + edge_width);
		if (n < threshold - edge_width) {
			discard;
		}
		float edge = 1.0 - smoothstep(threshold - edge_width, threshold, n);
		COLOR.rgb = mix(COLOR.rgb, edge_color.rgb, edge);
	}
}
