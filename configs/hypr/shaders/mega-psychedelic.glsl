precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

// User-controlled parameters (set these from the application side)
float swirlStrength = 1.0; // Swirl effect strength (0.0 to 1.0)
float colorCycleStrength = 1.0; // Color cycling strength (0.0 to 1.0)
float radialBlurStrength = 0.025; // Radial blur strength (0.0 to 1.0)
float vignetteStrength = 0.25; // Vignette effect strength (0.0 to 1.0)
float chromaticStrength = 0.25; // Chromatic aberration strength (0.0 to 1.0)
float edgeGlowStrength = 1.0; // Edge glow strength (0.0 to 1.0)

void main()
{
	vec2 uv = v_texcoord;
	vec2 center = vec2(0.5, 0.5);
	float radius = length(uv - center);
	float angle = atan(uv.y - center.y, uv.x - center.x);

	// Swirl effect with reduced distortion
	float swirl = sin(radius * 10.0 - time * 2.0) * 0.05 *
		      swirlStrength; // Reduced swirl intensity
	angle += swirl;

	// Polar to Cartesian conversion
	vec2 distortedUV = center + radius * vec2(cos(angle), sin(angle));

	// Radial blur effect with reduced distortion
	if (radialBlurStrength > 0.0) {
		vec2 blurDir = (distortedUV - center) * radialBlurStrength *
			       0.01; // Reduced blur intensity
		vec4 blurColor = vec4(0.0);
		float samples = 8.0;
		for (float i = 0.0; i < samples; i++) {
			blurColor += texture2D(tex, distortedUV + blurDir * i);
		}
		blurColor /= samples;
		distortedUV = mix(distortedUV, blurDir,
				  radialBlurStrength *
					  0.5); // Further reduce blur impact
	}

	// Clamp distortedUV to prevent excessive zooming
	distortedUV = clamp(distortedUV, 0.0, 1.0);

	// Sample the texture with distorted UV
	vec4 color = texture2D(tex, distortedUV);

	// Color cycling
	if (colorCycleStrength > 0.0) {
		color.rgb = vec3(
			color.r * (0.5 + 0.5 * sin(time) * colorCycleStrength),
			color.g * (0.5 +
				   0.5 * sin(time + 2.0) * colorCycleStrength),
			color.b * (0.5 +
				   0.5 * sin(time + 4.0) * colorCycleStrength));
	}

	// Chromatic aberration
	if (chromaticStrength > 0.0) {
		float aberration = 0.01 * chromaticStrength;
		float r = texture2D(tex, distortedUV + vec2(aberration, 0.0)).r;
		float g = texture2D(tex, distortedUV).g;
		float b = texture2D(tex, distortedUV - vec2(aberration, 0.0)).b;
		color.rgb = vec3(r, g, b);
	}

	// Vignette effect
	if (vignetteStrength > 0.0) {
		float vignette = 1.0 - length(uv - center) * vignetteStrength;
		color.rgb *= vignette;
	}

	// Edge glow effect with dynamic RGB color
	if (edgeGlowStrength > 0.0) {
		float glow = sin(radius * 20.0 - time * 5.0) * 0.5 + 0.5;

		// Dynamic RGB glow color based on time
		vec3 rgbGlow = vec3(0.5 + 0.5 * sin(time * 1.0), // Red
				    0.5 + 0.5 * sin(time * 1.5 + 2.0), // Green
				    0.5 + 0.5 * sin(time * 2.0 + 4.0) // Blue
		);

		// Apply the glow effect
		color.rgb += glow * edgeGlowStrength * rgbGlow;
	}

	gl_FragColor = color;
}
