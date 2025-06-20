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
