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
