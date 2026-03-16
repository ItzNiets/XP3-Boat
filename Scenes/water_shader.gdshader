shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;

// ==========================================
// STYLIZED OCEAN SHADER V6 — TUNED
// Faster, lower waves · Visible foam
// Contact foam · Domain-warped noise
// ==========================================

uniform vec3 color_deep : source_color = vec3(0.01, 0.12, 0.35);
uniform vec3 color_mid : source_color = vec3(0.04, 0.32, 0.58);
uniform vec3 color_shallow : source_color = vec3(0.1, 0.55, 0.78);
uniform vec3 color_foam : source_color = vec3(0.9, 0.97, 1.0);
uniform vec3 color_horizon : source_color = vec3(0.45, 0.7, 0.88);
uniform vec3 color_sss : source_color = vec3(0.05, 0.6, 0.45);
uniform float metallic : hint_range(0.0, 1.0) = 0.05;
uniform float roughness : hint_range(0.0, 1.0) = 0.12;

uniform float wave_time = 0.0;
uniform float overall_height : hint_range(0.0, 5.0) = 0.6;

// LOD cell size — set per ring from GDScript
uniform float cell_size : hint_range(0.25, 64.0) = 1.0;

// Contact foam
uniform float contact_foam_range : hint_range(0.01, 20.0) = 8.0;
uniform float contact_foam_power : hint_range(0.0, 5.0) = 2.5;

// Distance fade
uniform float fade_near : hint_range(10.0, 300.0) = 120.0;
uniform float fade_far : hint_range(100.0, 800.0) = 400.0;

// Depth texture
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

// ──── Hash / Noise helpers ────
vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float hash1(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float gradient_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

	return mix(
		mix(dot(hash2(i + vec2(0,0)), f - vec2(0,0)),
		    dot(hash2(i + vec2(1,0)), f - vec2(1,0)), u.x),
		mix(dot(hash2(i + vec2(0,1)), f - vec2(0,1)),
		    dot(hash2(i + vec2(1,1)), f - vec2(1,1)), u.x),
		u.y
	);
}

// ──── Voronoi for foam ────
float voronoi(vec2 p) {
	vec2 n = floor(p);
	vec2 f_part = fract(p);
	float d = 1.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = vec2(hash1(n + g), hash1(n + g + vec2(53.12, 97.34)));
			o = 0.5 + 0.5 * sin(wave_time * 0.6 + 6.2831 * o);
			vec2 diff = g + o - f_part;
			d = min(d, dot(diff, diff));
		}
	}
	return sqrt(d);
}

// ──── Ocean noise with domain warping ────
float ocean_noise(vec2 p, float t) {
	vec2 warp = vec2(
		gradient_noise(p * 0.04 + t * vec2(0.15, -0.09)),
		gradient_noise(p * 0.04 + t * vec2(-0.12, 0.17) + 50.0)
	);
	p += warp * 8.0;

	float val = 0.0;
	float amp = 0.5;
	float freq = 1.0;
	for (int i = 0; i < 5; i++) {
		vec2 uv = p * freq;
		float angle = float(i) * 1.1;
		float ca = cos(angle); float sa = sin(angle);
		uv = vec2(uv.x * ca - uv.y * sa, uv.x * sa + uv.y * ca);
		uv += t * vec2(0.5 + float(i) * 0.17, 0.3 - float(i) * 0.11);
		val += gradient_noise(uv) * amp;
		freq *= 2.13;
		amp *= 0.45;
	}
	return val;
}

// ──── Gerstner Wave ────
struct WaveParams {
	vec2 dir;
	float steepness;
	float wavelength;
};

vec3 gerstner(WaveParams w, vec2 pos, float t, inout vec3 tang, inout vec3 bino) {
	vec2 d = normalize(w.dir);
	float k = TAU / w.wavelength;
	float c = sqrt(9.8 / k);
	float f = k * (dot(d, pos) - c * t);
	float a = w.steepness / k;

	tang += vec3(-d.x*d.x * w.steepness * sin(f), d.x * w.steepness * cos(f), -d.x*d.y * w.steepness * sin(f));
	bino += vec3(-d.x*d.y * w.steepness * sin(f), d.y * w.steepness * cos(f), -d.y*d.y * w.steepness * sin(f));

	return vec3(d.x * a * cos(f), a * sin(f), d.y * a * cos(f));
}

varying float vert_height;
varying vec3 vert_world;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 pos = world_pos.xz;
	vec3 tang = vec3(1, 0, 0);
	vec3 bino = vec3(0, 0, 1);

	// 10 Gerstner waves — shorter wavelengths = faster visible motion, lower steepness = gentler
	WaveParams waves[10];
	waves[0] = WaveParams(vec2(1.0, 0.2),    0.06, 12.0);  // Fast primary chop
	waves[1] = WaveParams(vec2(-0.4, 1.0),   0.05, 9.0);   // Fast cross chop
	waves[2] = WaveParams(vec2(0.7, -0.6),   0.04, 15.0);  // Medium
	waves[3] = WaveParams(vec2(-0.6, 0.7),   0.035, 20.0); // Medium swell
	waves[4] = WaveParams(vec2(0.8, 0.8),    0.04, 7.0);   // Fast ripple
	waves[5] = WaveParams(vec2(-0.9, -0.3),  0.03, 25.0);  // Background swell
	waves[6] = WaveParams(vec2(0.3, -1.0),   0.025, 35.0); // Long diagonal
	waves[7] = WaveParams(vec2(-0.5, 0.5),   0.02, 50.0);  // Very long background
	waves[8] = WaveParams(vec2(1.0, -0.1),   0.05, 5.5);   // Quick short ripple
	waves[9] = WaveParams(vec2(-0.2, -0.9),  0.035, 8.0);  // Another cross ripple

	vec3 offset = vec3(0.0);
	for (int i = 0; i < 10; i++) {
		offset += gerstner(waves[i], pos, wave_time, tang, bino);
	}
	offset *= overall_height;

	// LOD-aware noise: fade for distant rings
	float lod_factor = clamp(1.0 - (cell_size - 1.0) / 15.0, 0.0, 1.0);

	// Micro detail (close-range organic bumps)
	float noise_micro = ocean_noise(pos * 0.08, wave_time * 0.2) * 0.15 * overall_height * lod_factor;
	// Macro variation (breaks large-scale pattern repetition)
	float noise_macro = ocean_noise(pos * 0.012, wave_time * 0.05) * 0.2 * overall_height;
	offset.y += noise_micro + noise_macro;

	VERTEX += offset;

	vec3 normal = normalize(cross(bino, tang));
	NORMAL = normal;

	vert_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	vert_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// ── Base color from height ──
	float h_norm = clamp(vert_height / (overall_height * 1.5) + 0.5, 0.0, 1.0);

	vec3 base_color;
	if (h_norm < 0.45) {
		base_color = mix(color_deep, color_mid, h_norm / 0.45);
	} else {
		base_color = mix(color_mid, color_shallow, (h_norm - 0.45) / 0.55);
	}

	// Domain-warped color variation
	float col_noise = ocean_noise(vert_world.xz * 0.01, wave_time * 0.04);
	base_color = mix(base_color, base_color * 1.15, col_noise * 0.3);

	// ── Wave-crest foam (Voronoi) — easier to trigger ──
	float crest = smoothstep(overall_height * 0.08, overall_height * 0.25, vert_height);
	float vor = voronoi(vert_world.xz * 0.25 + wave_time * 0.15);
	crest *= smoothstep(0.1, 0.45, 1.0 - vor);
	float crest_noise = ocean_noise(vert_world.xz * 0.15, wave_time * 0.5);
	crest *= smoothstep(0.0, 0.4, crest_noise);
	base_color = mix(base_color, color_foam, crest * 0.7);

	// ── Contact foam (depth-based) — much larger range + stronger ──
	float depth_raw = texture(depth_texture, SCREEN_UV).r;
	if (depth_raw < 1.0) {
		vec4 ndc = vec4(SCREEN_UV * 2.0 - 1.0, depth_raw, 1.0);
		vec4 view_depth = INV_PROJECTION_MATRIX * ndc;
		view_depth.xyz /= view_depth.w;

		float scene_z = -view_depth.z;
		float water_z = -VERTEX.z;
		float z_diff = abs(scene_z - water_z);

		float contact = 1.0 - smoothstep(0.0, contact_foam_range, z_diff);
		contact = pow(contact, 0.8) * contact_foam_power;

		// Animated Voronoi edge foam
		float foam_vor = voronoi(vert_world.xz * 0.5 + vec2(wave_time * 0.4, wave_time * 0.3));
		float foam_edge = smoothstep(0.0, 0.5, 1.0 - foam_vor);

		// Also add simple noise foam for softer fill
		float foam_noise = ocean_noise(vert_world.xz * 0.2, wave_time * 0.6);
		float foam_fill = smoothstep(0.0, 0.3, foam_noise) * 0.4;

		float total_foam = clamp(contact * (foam_edge + foam_fill), 0.0, 1.0);
		base_color = mix(base_color, color_foam, total_foam);
	}

	// ── Subsurface scattering approximation ──
	float sss = pow(max(dot(NORMAL, VIEW), 0.0), 2.0);
	float sss_height = smoothstep(overall_height * -0.1, overall_height * 0.3, vert_height);
	base_color = mix(base_color, color_sss, sss * sss_height * 0.12);

	// ── Fresnel rim ──
	float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 4.0);
	base_color = mix(base_color, color_shallow * 1.3, fresnel * 0.2);

	// ── Distance fade to horizon ──
	float cam_dist = length(VERTEX);
	float fade = smoothstep(fade_near, fade_far, cam_dist);
	base_color = mix(base_color, color_horizon, fade);

	ALBEDO = base_color;
	METALLIC = metallic;
	ROUGHNESS = mix(roughness, 0.5, fade);
	ALPHA = mix(0.92, 1.0, fade);
}
