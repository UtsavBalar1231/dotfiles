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
