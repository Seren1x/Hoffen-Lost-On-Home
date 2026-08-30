shader_type canvas_item;

// Fog / limited-visibility / vignette overlay.
// Applied to a full-screen ColorRect. All parameters are driven by the
// FogOverlay script at runtime (developer/designer tooling, not player settings).

// Radius of the fully-clear center, as a fraction of half the screen diagonal.
uniform float radius : hint_range(0.0, 1.0) = 0.55;
// How gradual the transition from clear to fully fogged.
uniform float softness : hint_range(0.0, 1.0) = 0.35;
// Max fog strength at the screen edge (0 = disabled, 1 = fully opaque).
uniform float darkness : hint_range(0.0, 1.0) = 0.9;
// Tint of the fog. Black = vignette; white/gray = mist.
uniform vec4 fog_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	// Normalized distance from center: 0 at center, 1 at the farthest corner.
	float dist = distance(UV, center) / length(center);
	// visibility is 1 (clear) in the center, fading to 0 at the fogged edge.
	float visibility = 1.0 - smoothstep(radius, radius + softness, dist);
	float fog_amount = 1.0 - visibility;
	COLOR = vec4(fog_color.rgb, fog_color.a * fog_amount * darkness);
}
