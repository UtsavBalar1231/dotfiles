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
