shader_type canvas_item;
// Fausse 3D : chaque sommet dessine par la carte (fond, traits, lettres, symboles) tourne autour du centre
// de la carte, puis est projete en perspective. Pas de texture intermediaire : le texte reste net.

uniform vec2 card_size = vec2(92.0, 132.0);
// Rotation en radians autour de l'axe x (haut / bas) et de l'axe y (gauche / droite). Pose par HandView.
uniform vec2 tilt = vec2(0.0);
// Distance de l'oeil a la carte, en pixels : plus petite = perspective plus marquee.
uniform float eye_distance = 400.0;

void vertex() {
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
