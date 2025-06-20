precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

// User-controlled bloom strength: 0.0 = no bloom, 1.0 = full bloom
float bloomStrength = 0.5;

void main()
{
	vec2 uv = v_texcoord;
	vec4 color = texture2D(tex, uv);

	// Simple bloom effect
	vec4 bloom = vec4(0.0);
	for (float x = -2.0; x <= 2.0; x += 1.0) {
		for (float y = -2.0; y <= 2.0; y += 1.0) {
			bloom += texture2D(tex, uv + vec2(x, y) * 0.005);
		}
	}
	bloom /= 25.0;

	// Combine with original color
	color.rgb += bloom.rgb * bloomStrength;

	gl_FragColor = color;
}
