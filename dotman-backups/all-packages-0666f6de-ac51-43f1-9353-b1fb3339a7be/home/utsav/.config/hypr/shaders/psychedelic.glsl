precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

// User-controlled swirl strength: 0.0 = no swirl, 1.0 = full swirl
float swirlStrength = 1.0;
// User-controlled color cycle strength: 0.0 = no color cycle, 1.0 = full color cycle
float colorCycleStrength = 1.0;

void main()
{
	vec2 uv = v_texcoord;
	vec2 center = vec2(0.5, 0.5);
	float radius = length(uv - center);
	float angle = atan(uv.y - center.y, uv.x - center.x);

	// Swirl effect
	float swirl = sin(radius * 10.0 - time * 2.0) * 0.1 * swirlStrength;
	angle += swirl;

	// Polar to Cartesian conversion
	vec2 distortedUV = center + radius * vec2(cos(angle), sin(angle));

	vec4 color = texture2D(tex, distortedUV);

	// Color cycling
	color.rgb = vec3(
		color.r * (0.5 + 0.5 * sin(time) * colorCycleStrength),
		color.g * (0.5 + 0.5 * sin(time + 2.0) * colorCycleStrength),
		color.b * (0.5 + 0.5 * sin(time + 4.0) * colorCycleStrength));

	gl_FragColor = color;
}
