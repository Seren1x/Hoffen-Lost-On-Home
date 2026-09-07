shader_type canvas_item;

// PanelBackground shader
// Reveals `city_tex` only inside several vertical, slightly-tilted polygon
// panels; everything outside is black (or a solid backdrop color). The panel
// shapes are computed here in Godot -- nothing is hand-drawn.
//
// Adjust all parameters on the node's script (PanelBackground) in the
// Inspector. This shader just reads uniforms.

uniform sampler2D city_tex : filter_linear_mipmap, repeat_disable;
uniform bool use_texture = true;

uniform int panel_count : hint_range(1, 12) = 4;
uniform float panel_width : hint_range(0.01, 1.0) = 0.22;
uniform float panel_gap : hint_range(0.0, 0.5) = 0.012;
uniform float panel_heights[16];    // per-panel vertical extent (0..1+)
uniform float panel_v_centers[16];  // per-panel vertical position (0..1)
uniform float panel_phases[16];     // per-panel bob phase in radians (PI = opposite)
uniform float h_offset : hint_range(-1.0, 1.0) = 0.0;
uniform float tilt : hint_range(-0.5, 0.5) = 0.04;
uniform float v_offset : hint_range(-1.0, 1.0) = 0.0;

uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 backdrop : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Panel bobbing animation (whole band moves up/down, per-panel offsets kept).
uniform bool anim_enabled = false;
uniform float anim_speed : hint_range(0.0, 5.0) = 1.0;
uniform float anim_amplitude : hint_range(0.0, 0.5) = 0.04;
uniform float anim_time = 0.0;

void fragment() {
	vec2 uv = UV;
	vec3 col = backdrop.rgb;

	// Horizontal shift of the whole panel set.
	float x = uv.x + h_offset;

	// Correct for tilt so membership is decided on the UNtilted axis.
	float x_untilt = x - tilt * (uv.y - 0.5);

	float span = panel_width + panel_gap;
	float total = float(panel_count) * span - panel_gap;
	float start = 0.5 - total * 0.5;
	float rel = x_untilt - start;
	int idx = int(floor(rel / span));
	float within = rel - float(idx) * span;
	if (idx >= 0 && idx < panel_count && within < panel_width) {
		// Per-panel vertical band check. Each panel bobs with its own phase
		// (phase PI = moves opposite to phase 0).
		float ph = panel_heights[idx];
		float bob = 0.0;
		if (anim_enabled) {
			bob = sin(anim_time * anim_speed + panel_phases[idx]) * anim_amplitude;
		}
		float pvc = panel_v_centers[idx] + bob;
		if (abs(uv.y - pvc) < ph * 0.5) {
			if (use_texture) {
				vec3 tc = texture(city_tex, uv + vec2(0.0, v_offset)).rgb;
				col = tc * tint.rgb;
			} else {
				col = tint.rgb;
			}
		}
	}

	COLOR = vec4(col, 1.0);
}
