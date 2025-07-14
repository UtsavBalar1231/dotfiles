// from https://github.com/hyprwm/Hyprland/issues/1140#issuecomment-1335128437

precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

const float temperature = 5000.0;
const float temperatureStrength = 1.0;

#define WithQuickAndDirtyLuminancePreservation
const float LuminancePreservationFactor = 1.0;

// function from https://www.shadertoy.com/view/4sc3D7
// valid from 1000 to 40000 K (and additionally 0 for pure full white)
vec3 colorTemperatureToRGB(const in float temperature) {
    // values from: http://blenderartists.org/forum/showthread.php?270332-OSL-Goodness&p=2268693&viewfull=1#post2268693
    mat3 m = (temperature <= 6500.0) ? mat3(vec3(0.0, -2902.1955373783176, -8257.7997278925690),
                                            vec3(0.0, 1669.5803561666639, 2575.2827530017594),
                                            vec3(1.0, 1.3302673723350029, 1.8993753891711275))
                                     : mat3(vec3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
                                            vec3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
                                            vec3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));
    return mix(clamp(vec3(m[0] / (vec3(clamp(temperature, 1000.0, 40000.0)) + m[1]) + m[2]), vec3(0.0), vec3(1.0)),
               vec3(1.0), smoothstep(1000.0, 0.0, temperature));
}

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);

    // RGB
    vec3 color = vec3(pixColor[0], pixColor[1], pixColor[2]);

#ifdef WithQuickAndDirtyLuminancePreservation
    color *= mix(1.0, dot(color, vec3(0.2126, 0.7152, 0.0722)) / max(dot(color, vec3(0.2126, 0.7152, 0.0722)), 1e-5),
                 LuminancePreservationFactor);
#endif

    color = mix(color, color * colorTemperatureToRGB(temperature), temperatureStrength);

    vec4 outCol = vec4(color, pixColor[3]);

    gl_FragColor = outCol;
}
precision highp float;
varying highp vec2 v_texcoord;
uniform highp sampler2D tex;

#define STRENGTH 0.0027

void main() {
    vec2 center = vec2(0.5, 0.5);
    vec2 offset = (v_texcoord - center) * STRENGTH;

    float rSquared = dot(offset, offset);
    float distortion = 1.0 + 1.0 * rSquared;
    vec2 distortedOffset = offset * distortion;

    vec2 redOffset = vec2(distortedOffset.x, distortedOffset.y);
    vec2 blueOffset = vec2(distortedOffset.x, distortedOffset.y);

    vec4 redColor = texture2D(tex, v_texcoord + redOffset);
    vec4 blueColor = texture2D(tex, v_texcoord + blueOffset);

    gl_FragColor = vec4(redColor.r, texture2D(tex, v_texcoord).g, blueColor.b, 1.0);
}
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {

    vec4 pixColor = texture2D(tex, v_texcoord);

    // red
    pixColor[0] *= 0.7;
    // green
    pixColor[1] *= 0.6;
    // blue
    pixColor[2] *= 0.5;

    gl_FragColor = pixColor;
}
precision lowp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

float distanceSquared(vec3 pixColor, vec3 solarizedColor) {
	vec3 distanceVector = pixColor - solarizedColor;
	return dot(distanceVector, distanceVector);
}

void main() {
	vec3 solarized[16];
	solarized[0]  = vec3(0.,0.169,0.212);
	solarized[1]  = vec3(0.027,0.212,0.259);
	solarized[2]  = vec3(0.345,0.431,0.459);
	solarized[3]  = vec3(0.396,0.482,0.514);
	solarized[4]  = vec3(0.514,0.58,0.588);
	solarized[5]  = vec3(0.576,0.631,0.631);
	solarized[6]  = vec3(0.933,0.91,0.835);
	solarized[7]  = vec3(0.992,0.965,0.89);
	solarized[8]  = vec3(0.71,0.537,0.);
	solarized[9]  = vec3(0.796,0.294,0.086);
	solarized[10] = vec3(0.863,0.196,0.184);
	solarized[11] = vec3(0.827,0.212,0.51);
	solarized[12] = vec3(0.424,0.443,0.769);
	solarized[13] = vec3(0.149,0.545,0.824);
	solarized[14] = vec3(0.165,0.631,0.596);
	solarized[15] = vec3(0.522,0.6,0.);

	vec3 pixColor = vec3(texture2D(tex, v_texcoord));
	int closest = 0;
	float closestDistanceSquared = distanceSquared(pixColor, solarized[0]);
	for (int i = 1; i < 15; i++) {
		float newDistanceSquared = distanceSquared(pixColor, solarized[i]);
		if (newDistanceSquared < closestDistanceSquared) {
			closest = i;
			closestDistanceSquared = newDistanceSquared;
		}
	}
	gl_FragColor = vec4(solarized[closest], 1.);
}
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);

    // Convert to grayscale
    float gray = dot(pixColor.rgb, vec3(0.299, 0.587, 0.114));

    gl_FragColor = vec4(vec3(gray), pixColor.a);
}
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);

    // Calculate vignette effect
    vec2 uv = v_texcoord * 2.0 - 1.0;
    float vignette = 1.0 - dot(uv, uv) * 0.5;

    // Apply vignette
    gl_FragColor = vec4(pixColor.rgb * vignette, pixColor.a);
}
// CRT like monitor shaders for hyprland (thanks to https://www.shadertoy.com/user/sprash3)

precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

const float DENSITY = 1.3;
const float S_OPASITY = 0.3;
const float N_OPASITY = 0.2;
const float FLICKERING = 0.03;
const float WIDTH = 0.84;
const float HEIGHT = 0.5;
const float CURVE = 4.0;
const float SMOOTH = 0.004;
const float SHINE = 0.12;

const vec2 RESOLUTION = vec2(1920, 1200);

const vec3 BEZEL_COL = vec3(0.8, 0.8, 0.6);

// Function to calculate curved surface.
vec2 curvedSurface(vec2 uv, float r)
{
    return r * uv/sqrt(r * r - dot(uv, uv));
}

// Function to calculate CRT curve.
vec2 crtCurve(vec2 uv, float r, bool content, bool shine)
{
    r = CURVE * r;
    uv = (uv / RESOLUTION - 0.5) / vec2(RESOLUTION.y/RESOLUTION.x, 1.) * 2.0;
    uv = curvedSurface(uv, r);
    if(content) uv *= 0.5 / vec2(WIDTH, HEIGHT);
    uv = (uv / 2.0) + 0.5;
    
    return uv;    
}

float random(vec2 st) 
{
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float blend(const in float x, const in float y) 
{
    return (x < 0.5) ? (2.0 * x * y) : (1.0 - 2.0 * (1.0 - x) * (1.0 - y));
}

vec3 blend(const in vec3 x, const in vec3 y, const in float opacity) 
{
    vec3 z = vec3(blend(x.r, y.r), blend(x.g, y.g), blend(x.b, y.b));
    return z * opacity + x * (1.0 - opacity);
}

float roundSquare(vec2 p, vec2 b, float r)
{
    return length(max(abs(p)-b,0.0))-r;
}

float stdRS(vec2 uv, float r)
{
    return roundSquare(uv - 0.5, vec2(WIDTH, HEIGHT) + r, 0.05);
}

void main()
{    
    vec3 content = vec3(0.0, 0.0, 0.0);
    vec3 gloss = vec3(0.0, 0.0, 0.0);

    vec2 uvContent = crtCurve(gl_FragCoord.xy, 1., true, false);
    vec2 uvScreen = crtCurve(gl_FragCoord.xy, 1., false, false);
    vec2 uvEnclosure = crtCurve(gl_FragCoord.xy, 1.25, false, false);
    vec2 uvShine = crtCurve(gl_FragCoord.xy, 1., false, true);

    float count = 1400.0 * DENSITY;
    vec2 sl = vec2(sin(uvContent.y * count), cos(uvContent.y * count));
    vec3 scanlines = vec3(sl.x, sl.y, sl.x);

    const float HHW = 0.5 * HEIGHT/WIDTH;

    content += BEZEL_COL * SHINE * 0.7 *
        smoothstep(-SMOOTH, SMOOTH, stdRS(uvScreen, 0.0)) * 
        smoothstep(SMOOTH, -SMOOTH, stdRS(uvEnclosure, 0.05));

    content -= (BEZEL_COL) *
        smoothstep(-SMOOTH*2.0, SMOOTH*10.0, stdRS(uvEnclosure, 0.05)) *
        smoothstep(SMOOTH*2.0, -SMOOTH*2.0, stdRS(uvEnclosure, 0.05));

    content += max(0.0, SHINE - 0.3*distance(uvScreen, vec2(0.5,0.5))) *
            smoothstep(SMOOTH, -SMOOTH, stdRS(uvScreen, 0.0));

    vec3 col = texture2D(tex, uvContent).xyz;
    if (uvContent.x > 0. && uvContent.x < 1. && uvContent.y > 0. && uvContent.y < 1.)
    {
        col += col * scanlines * S_OPASITY;
        col += col * vec3(random(uvContent * time)) * N_OPASITY;
        col += col * sin(110.0 * time) * FLICKERING;
        content += col;
    }

    gl_FragColor = vec4(content, 1.0);
}
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

uniform float time; // Pass time as a uniform for animation

void main() {
    // Create distortion effect
    vec2 uv = v_texcoord;
    uv.x += sin(uv.y * 10.0 + time * 2.0) * 0.01;
    uv.y += cos(uv.x * 10.0 + time * 2.0) * 0.01;

    vec4 pixColor = texture2D(tex, uv);

    gl_FragColor = pixColor;
}
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

#define blurStrength 0.0025 // Adjust blur strength

void main() {
    vec2 center = vec2(0.5, 0.5); // Center of the screen
    vec2 uv = v_texcoord - center;
    float dist = length(uv);

    vec4 color = vec4(0.0);
    float samples = 16.0;

    for (float i = 0.0; i < samples; i++) {
        float angle = 6.28318530718 * (i / samples);
        vec2 offset = uv + vec2(cos(angle), sin(angle)) * dist * blurStrength;
        color += texture2D(tex, offset + center);
    }

    color /= samples;

    gl_FragColor = color;
}
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

#define STRENGTH 1.25 // Adjust blur strength (higher values = stronger blur)

void main() {
    vec2 texelSize = vec2(1.0 / 1920.0, 1.0 / 1080.0); // Adjust for your resolution
    vec4 color = vec4(0.0);

    // Apply Gaussian blur
    for (float x = -STRENGTH; x <= STRENGTH; x++) {
        for (float y = -STRENGTH; y <= STRENGTH; y++) {
            color += texture2D(tex, v_texcoord + vec2(x, y) * texelSize);
        }
    }

    // Normalize the result
    color /= pow(2.0 * STRENGTH + 1.0, 2.0);

    gl_FragColor = color;
}
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);

    // Calculate vignette
    vec2 uv = v_texcoord * 2.0 - 1.0;
    float vignette = 1.0 - dot(uv, uv) * 0.5;

    // Calculate radial gradient
    float gradient = 1.0 - length(uv) * 0.7;

    // Combine effects
    vec3 finalColor = pixColor.rgb * vignette * gradient;

    gl_FragColor = vec4(finalColor, pixColor.a);
}
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

vec3 heatmap(float value) {
    vec3 color = vec3(0.0);
    color.r = smoothstep(0.0, 0.5, value);
    color.g = smoothstep(0.5, 1.0, value);
    color.b = smoothstep(1.0, 1.5, value);

    return color;
}

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);

    // Convert brightness to heatmap
    float brightness = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 heatColor = heatmap(brightness);

    gl_FragColor = vec4(heatColor, pixColor.a);
}
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

uniform float time; // Pass time as a uniform for animation

void main() {
    vec2 uv = v_texcoord;

    // Create wavy distortion
    uv.x += sin(uv.y * 10.0 + time * 2.0) * 0.01;
    uv.y += cos(uv.x * 10.0 + time * 2.0) * 0.01;

    vec4 pixColor = texture2D(tex, uv);

    // Apply blue tint for underwater effect
    pixColor.rgb *= vec3(0.5, 0.8, 1.0);

    gl_FragColor = pixColor;
}
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

#define aberrationStrength 0.00096

void main() {
    vec2 uv = v_texcoord;

    // Split RGB channels
    float r = texture2D(tex, uv + vec2(aberrationStrength, 0.0)).r;
    float g = texture2D(tex, uv).g;
    float b = texture2D(tex, uv - vec2(aberrationStrength, 0.0)).b;

    gl_FragColor = vec4(r, g, b, 1.0);
}
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
// from https://github.com/hyprwm/Hyprland/issues/1140#issuecomment-1614863627

precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

// see https://github.com/CeeJayDK/SweetFX/blob/a792aee788c6203385a858ebdea82a77f81c67f0/Shaders/Vibrance.fx#L20-L30
const vec3 VIB_RGB_BALANCE = vec3(1.0, 1.0, 1.0);
const float VIB_VIBRANCE = 0.1;


const vec3 VIB_coeffVibrance = VIB_RGB_BALANCE * -VIB_VIBRANCE;

void main() {

    vec4 pixColor = texture2D(tex, v_texcoord);

    // RGB
    vec3 color = vec3(pixColor[0], pixColor[1], pixColor[2]);


    // vec3 VIB_coefLuma = vec3(0.333333, 0.333334, 0.333333); // was for `if VIB_LUMA == 1`
    vec3 VIB_coefLuma = vec3(0.212656, 0.715158, 0.072186); // try both and see which one looks nicer.

    float luma = dot(VIB_coefLuma, color);

    float max_color = max(color[0], max(color[1], color[2]));
    float min_color = min(color[0], min(color[1], color[2]));

    float color_saturation = max_color - min_color;

    vec3 p_col = vec3(vec3(vec3(vec3(sign(VIB_coeffVibrance) * color_saturation) - 1.0) * VIB_coeffVibrance) + 1.0);

    pixColor[0] = mix(luma, color[0], p_col[0]);
    pixColor[1] = mix(luma, color[1], p_col[1]);
    pixColor[2] = mix(luma, color[2], p_col[2]);

    gl_FragColor = pixColor;
}
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
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

// Cherry Blossom Parameters
float blossomDensity = 100.0;      // More blossoms
float blossomSpeed = 2.0;          // Faster falling
float blossomSize = 0.03;          // Larger blossoms
vec3 blossomColor = vec3(1.0, 0.5, 0.7); // Lighter pink

// Rain Parameters
float rainDensity = 200.0;         // More rain
float rainSpeed = 3.0;             // Faster falling
float rainWidth = 0.003;           // Thicker raindrops
float rainLength = 0.15;           // Longer raindrops
vec3 rainColor = vec3(0.4, 0.6, 1.0); // Deeper blue

// Background Parameters
vec3 backgroundColor = vec3(0.8, 0.9, 1.0); // Brighter sky
// Helper function to generate random noise
float random(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Helper function to generate smooth noise
float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Helper function to draw a cherry blossom
float drawBlossom(vec2 uv, vec2 pos, float size) {
    float dist = length(uv - pos);
    return smoothstep(size, size * 0.5, dist); // Smooth circle
}

// Helper function to draw a raindrop
float drawRain(vec2 uv, vec2 pos, float width, float length) {
    float distX = abs(uv.x - pos.x);
    float distY = uv.y - pos.y; // Raindrops fall downward
    return smoothstep(width, 0.0, distX) * smoothstep(length, 0.0, distY);
}

void main()
{
    vec2 uv = v_texcoord;

    // Initialize background color
    vec3 color = backgroundColor;

    // Draw cherry blossoms
    for (float i = 0.0; i < blossomDensity; i++) {
        // Randomize blossom position and movement
        vec2 blossomPos = vec2(
            random(vec2(i, 0.0)), // X position
            fract(time * blossomSpeed * 0.1 + random(vec2(i, 1.0))) // Y position (falling)
        );
        // Draw the blossom
        float blossom = drawBlossom(uv, blossomPos, blossomSize);
        color = mix(color, blossomColor, blossom);
    }

    // Draw rain
    for (float i = 0.0; i < rainDensity; i++) {
        // Randomize raindrop position and movement
        vec2 rainPos = vec2(
            random(vec2(i, 2.0)), // X position
            fract(time * rainSpeed * 0.1 + random(vec2(i, 3.0))) // Y position (falling)
        );
        // Draw the raindrop
        float rain = drawRain(uv, rainPos, rainWidth, rainLength);
        color = mix(color, rainColor, rain);
    }

    // Sample the texture and blend with the effects
    vec4 textureColor = texture2D(tex, uv);
    color = mix(color, textureColor.rgb, textureColor.a);

    gl_FragColor = vec4(color, 1.0);
}
