precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

// User-controlled parameters
float bleedStrength = 0.05; // Controls the amount of color bleed (0 to disable)
float scanlineStrength = 1.0; // Controls the intensity of scanlines (0 to disable)
float flickerStrength = 1.0; // Controls the intensity of flickering (0 to disable)

void main() {
    vec2 uv = v_texcoord;

    // Apply color bleeding if bleedStrength > 0
    if (bleedStrength <= 0.0) {
		gl_FragColor = texture2D(tex, uv);
		return;
	}
    float bleed = 0.02 * bleedStrength;
    float r = texture2D(tex, uv + vec2(bleed, 0.0)).r;
    float g = texture2D(tex, uv).g;
    float b = texture2D(tex, uv - vec2(bleed, 0.0)).b;

    vec4 color = vec4(r, g, b, 1.0);

    // Apply scanlines if scanlineStrength > 0
    if (scanlineStrength > 0.0) {
        float scanline = scanlineStrength * (sin(uv.y * 800.0) * 0.1 + 0.9);
        color.rgb *= scanline;
    }

    // Apply flickering if flickerStrength > 0
    if (flickerStrength > 0.0) {
        color.rgb *= (0.9 + 0.1 * sin(time * 10.0)) * flickerStrength;
    }

    gl_FragColor = color;
}
