precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

// User-controlled warp strength: 0.0 = no warp, 1.0 = full warp
uniform float warpStrength = 1.0;
// User-controlled color shift strength: 0.0 = no color shift, 1.0 = full color shift
uniform float colorShiftStrength = 1.0;

void main()
{
	vec2 uv = v_texcoord;
	vec2 center = vec2(0.5, 0.5);
	float radius = length(uv - center);

	// Time warp effect
	float warp = sin(radius * 10.0 - time * 2.0) * 0.1 * warpStrength;
	uv += warp * (uv - center);

	vec4 color = texture2D(tex, uv);

	// Add some color shifting
	color.rgb = vec3(
		color.r * (0.5 + 0.5 * sin(time * 1.0) * colorShiftStrength),
		color.g * (0.5 + 0.5 * sin(time * 1.5) * colorShiftStrength),
		color.b * (0.5 + 0.5 * sin(time * 2.0) * colorShiftStrength));

	gl_FragColor = color;
}
