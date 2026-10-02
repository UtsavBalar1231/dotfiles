precision mediump float;
precision mediump int;

uniform sampler2D tex;
uniform float iTime;
varying vec2 v_texcoord;

// Forward declarations
float hash(vec2 p);
float noise(vec2 p);
float getEInkLevel(float value, int levels);

// Hash function for generating noise
float hash(vec2 p) {
    p = 50.0*fract(p*0.3183099);
    return fract(p.x*p.y*(p.x+p.y));
}

// Noise function for paper texture and grain
float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(hash(ip), hash(ip+vec2(1.0,0.0)), u.x),
        mix(hash(ip+vec2(0.0,1.0)), hash(ip+vec2(1.0,1.0)), u.x), u.y);
    return res*res;
}

// E-ink has multiple grayscale levels (typically 4-16)
float getEInkLevel(float value, int levels) {
    return floor(value * float(levels)) / float(levels - 1);
}

void main() {
    vec2 uv = v_texcoord;
    vec4 color = texture2D(tex, uv);
    
    // Convert to grayscale
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Paper texture (subtle noise)
    float paperGrain = noise(uv * 500.0) * 0.05;
    
    // Create several different noise patterns at different scales
    float noise1 = noise(uv * 200.0) * 0.03;
    float noise2 = noise(uv * 400.0 + iTime * 0.1) * 0.02;
    
    // Apply paper texture and grain
    gray = gray + paperGrain + noise1 - noise2;
    
    // Simulate ghosting with a time-based noise pattern
    // This creates a subtle shift that resembles ghosting
    float pseudoGhosting = noise(uv * 300.0 + vec2(iTime * 0.05, 0.0)) * 0.08;
    gray = mix(gray, pseudoGhosting, 0.1);
    
    // Apply multiple grayscale levels (simulate real e-ink resolution)
    int levels = 4; // Most e-ink displays have 4-16 grayscale levels
    float e_ink = getEInkLevel(gray, levels);
    
    // Apply slight random variation to create more realistic pixel distribution
    float randomVar = noise(uv * 1000.0 + vec2(iTime * 0.01, 0.0)) * 0.05;
    e_ink = clamp(e_ink + randomVar, 0.0, 1.0);
    
    // Additional tweaks for better realism
    // Using fixed pixel size
    vec2 pixelSize = vec2(0.001, 0.001);
    float neighbor1 = texture2D(tex, uv + pixelSize).r;
    float neighbor2 = texture2D(tex, uv - pixelSize).r;
    
    // Add subtle edge enhancement (e-ink displays often have sharper edges)
    float edgeEnhance = abs(neighbor1 - neighbor2) * 0.15;
    e_ink = clamp(e_ink + edgeEnhance, 0.0, 1.0);
    
    // Add very subtle refresh anomalies (occasional lines)
    float refreshLine = step(0.995, fract(uv.y * 50.0 + iTime * 0.1)) * 0.05;
    e_ink = mix(e_ink, 1.0, refreshLine);
    
    gl_FragColor = vec4(vec3(e_ink), 1.0);
} 