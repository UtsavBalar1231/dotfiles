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
