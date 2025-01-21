precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

// User-controlled parameters (set these from the application side)
float rippleStrength = 0.05; // Strength of water ripple effect (0.0 to 1.0)
float glowStrength = 0.025; // Strength of glowing light effect (0.0 to 1.0)
float colorShiftStrength =
	1.0; // Strength of gradient color transitions (0.0 to 1.0)
float particleStrength = 0.00025; // Strength of particle-like effects (0.0 to 1.0)

// Helper function to generate smooth noise
float smoothNoise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = dot(i, vec2(12.9898, 78.233));
	float b = dot(i + vec2(1.0, 0.0), vec2(12.9898, 78.233));
	float c = dot(i + vec2(0.0, 1.0), vec2(12.9898, 78.233));
	float d = dot(i + vec2(1.0, 1.0), vec2(12.9898, 78.233));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Helper function to generate water ripple effect
vec2 rippleEffect(vec2 uv, float strength)
{
	vec2 center = vec2(0.5, 0.5);
	float radius = length(uv - center);
	float angle = atan(uv.y - center.y, uv.x - center.x);

	// Ripple distortion
	float ripple = sin(radius * 20.0 - time * 2.0) * 0.02 * strength;
	uv += ripple * normalize(uv - center);

	return uv;
}

// Helper function to generate glowing light effect
vec3 glowEffect(vec2 uv, float strength)
{
	vec2 center = vec2(0.5, 0.5);
	float radius = length(uv - center);

	// Glow intensity
	float glow = smoothstep(0.5, 0.0, radius) * strength;

	// Soft glowing color (pastel tones)
	vec3 glowColor = vec3(0.7 + 0.3 * sin(time * 0.5), // Soft pink
			      0.7 + 0.3 * sin(time * 0.7 + 2.0), // Soft green
			      0.7 + 0.3 * sin(time * 0.9 + 4.0) // Soft blue
	);

	return glowColor * glow;
}

// Helper function to generate gradient color transitions
vec3 gradientColor(vec2 uv, float strength)
{
	// Gradient based on vertical position
	vec3 topColor = vec3(0.2, 0.4, 0.6); // Soft blue
	vec3 bottomColor = vec3(0.6, 0.4, 0.2); // Soft orange
	vec3 gradient = mix(topColor, bottomColor, uv.y);

	// Add subtle color shifts over time
	gradient.r += 0.1 * sin(time * 0.3) * strength;
	gradient.g += 0.1 * sin(time * 0.5 + 2.0) * strength;
	gradient.b += 0.1 * sin(time * 0.7 + 4.0) * strength;

	return gradient;
}

// Helper function to generate particle-like effects
vec3 particleEffect(vec2 uv, float strength)
{
	// Generate random particle positions
	float particle = smoothNoise(uv * 10.0 + time * 0.5) * strength;

	// Particle color (soft white)
	vec3 particleColor = vec3(1.0, 1.0, 1.0) * particle;

	return particleColor;
}

void main()
{
	vec2 uv = v_texcoord;

	// Apply water ripple effect
	if (rippleStrength > 0.0) {
		uv = rippleEffect(uv, rippleStrength);
	}

	// Sample the texture with distorted UV
	vec4 color = texture2D(tex, uv);

	// Apply gradient color transitions
	if (colorShiftStrength > 0.0) {
		vec3 gradient = gradientColor(uv, colorShiftStrength);
		color.rgb = mix(color.rgb, gradient, 0.5);
	}

	// Apply glowing light effect
	if (glowStrength > 0.0) {
		vec3 glow = glowEffect(uv, glowStrength);
		color.rgb += glow *
			     0.5; // Reduce glow intensity to avoid overexposure
	}

	// Apply particle-like effects
	if (particleStrength > 0.0) {
		vec3 particles = particleEffect(uv, particleStrength);
		color.rgb +=
			particles *
			0.3; // Reduce particle intensity to avoid overexposure
	}

	// Soft vignette effect
	float vignette = 1.0 - length(uv - vec2(0.5, 0.5)) * 0.5;
	color.rgb *= vignette;

	// Ensure the color doesn't go completely white
	color.rgb = clamp(color.rgb, 0.0, 1.0);

	gl_FragColor = color;
}
