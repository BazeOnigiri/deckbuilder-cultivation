shader_type canvas_item;
// Lune du menu : disque pale aux mers d'ombre, halo, bande de nuages qui passe devant.
// Dessinee dans un rectangle carre (UV 0 a 1).

#include "res://ui/theme/bruit.gdshaderinc"

uniform vec4 moon_color : source_color = vec4(0.93, 0.88, 0.74, 1.0);
uniform vec4 shade_color : source_color = vec4(0.72, 0.66, 0.55, 1.0);
uniform vec4 halo_color : source_color = vec4(0.93, 0.85, 0.62, 0.35);
uniform vec4 cloud_color : source_color = vec4(0.06, 0.09, 0.13, 0.85);
// Rayon du disque et largeur du halo, en part du rectangle.
uniform float radius = 0.3;
uniform float halo = 0.18;
uniform float cloud_speed = 0.015;
global uniform float motion_scale;

void fragment() {
	vec2 p = UV - 0.5;
	float d = length(p);
	float disc = 1.0 - smoothstep(radius - 0.006, radius, d);
	// Mers sombres de la lune : bruit fixe, un peu plus sombre vers le bord.
	float seas = smoothstep(0.45, 0.75, fbm(UV * 5.0 + vec2(2.3, 7.1)));
	vec3 moon = mix(moon_color.rgb, shade_color.rgb, seas * 0.7 + smoothstep(0.0, radius, d) * 0.15);
	float glow = pow(1.0 - smoothstep(radius, radius + halo, d), 2.0) * halo_color.a;
	vec4 color = mix(vec4(halo_color.rgb, glow), vec4(moon, 1.0), disc);
	// Nuages : bande horizontale de bruit etire qui derive.
	float t = TIME * cloud_speed * motion_scale;
	float cloud = fbm(vec2(UV.x * 2.0 + t, UV.y * 6.0));
	float band = smoothstep(0.5, 0.75, cloud) * smoothstep(0.42, 0.55, UV.y) * (1.0 - smoothstep(0.62, 0.78, UV.y));
	// Effiloches sur les cotes : pas de bord net au bout du rectangle.
	band *= smoothstep(0.0, 0.3, UV.x) * (1.0 - smoothstep(0.7, 1.0, UV.x));
	color.rgb = mix(color.rgb, cloud_color.rgb, band * cloud_color.a);
	color.a = max(color.a, band * cloud_color.a);
	COLOR = color;
}
