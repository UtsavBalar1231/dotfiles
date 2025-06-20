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
