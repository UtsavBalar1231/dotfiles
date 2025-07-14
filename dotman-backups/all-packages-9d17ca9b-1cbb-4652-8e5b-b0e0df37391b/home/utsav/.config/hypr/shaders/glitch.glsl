precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

// User-controlled glitch strength: 0.0 = no glitch, 1.0 = full glitch
float glitchStrength = 0.025;
// User-controlled noise strength: 0.0 = no noise, 1.0 = full noise
float noiseStrength = 0.025;

float rand(vec2 co)
{
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main()
{
	vec2 uv = v_texcoord;

	// Random horizontal shift
	float shift = rand(vec2(time, uv.y)) * 0.1 * glitchStrength;
	uv.x += shift;

	// Color channel separation
	float r = texture2D(tex, uv + vec2(0.01 * glitchStrength, 0.0)).r;
	float g = texture2D(tex, uv).g;
	float b = texture2D(tex, uv - vec2(0.01 * glitchStrength, 0.0)).b;

	vec4 color = vec4(r, g, b, 1.0);

	// Random noise
	color.rgb += vec3(rand(uv + time) * 0.1 * noiseStrength);

	gl_FragColor = color;
}
