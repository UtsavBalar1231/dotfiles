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
