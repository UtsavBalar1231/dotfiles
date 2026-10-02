precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

// User-controlled neon glow strength: 0.0 = no glow, 1.0 = full glow
float neonStrength = 0.5;

void main()
{
	vec2 uv = v_texcoord;
	vec4 color = texture2D(tex, uv);

	// Neon glow effect
	vec3 neon = vec3(color.r * color.r * 2.0, color.g * color.g * 2.0,
			 color.b * color.b * 2.0);

	// Combine with original color
	color.rgb += neon * neonStrength;

	gl_FragColor = color;
}
