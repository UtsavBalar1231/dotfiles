precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

// User-controlled zoom strength: 0.0 = no zoom, 1.0 = full zoom
float zoomStrength = 0.1;
// User-controlled color shift strength: 0.0 = no color shift, 1.0 = full color shift
float colorShiftStrength = 0.5;

vec2 fractalZoom(vec2 uv, float zoom, float speed)
{
	uv = uv * 2.0 - 1.0;
	float scale = 1.0 / zoom;
	uv *= scale;
	uv += vec2(sin(time * speed), cos(time * speed)) * 0.1;
	return uv * 0.5 + 0.5;
}

void main()
{
	vec2 uv = v_texcoord;
	uv = fractalZoom(uv, 1.0 + sin(time) * zoomStrength, 1.0);

	vec4 color = texture2D(tex, uv);

	// Add some color shifting
	color.rgb = vec3(
		color.r * (0.5 + 0.5 * sin(time * 1.0) * colorShiftStrength),
		color.g * (0.5 + 0.5 * sin(time * 1.5) * colorShiftStrength),
		color.b * (0.5 + 0.5 * sin(time * 2.0) * colorShiftStrength));

	gl_FragColor = color;
}
