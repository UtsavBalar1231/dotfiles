uniform sampler2D tex;
varying vec2 texCoord;

// Bayer 4x4 Dithering Matrix
const mat4 bayer = mat4(
    1.0,  9.0,  3.0, 11.0,
   13.0,  5.0, 15.0,  7.0,
    4.0, 12.0,  2.0, 10.0,
   16.0,  8.0, 14.0,  6.0
) / 17.0;

void main() {
    vec2 uv = texCoord;
    vec4 color = texture2D(tex, uv);
    
    // Convert to grayscale
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Get Bayer threshold
    ivec2 pos = ivec2(mod(gl_FragCoord.xy, 4.0));
    float threshold = bayer[pos.x][pos.y];
    
    // Apply dithering
    float dithered = gray < threshold ? 0.0 : 1.0;
    
    gl_FragColor = vec4(vec3(dithered), 1.0);
}
