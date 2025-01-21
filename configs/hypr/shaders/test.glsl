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
