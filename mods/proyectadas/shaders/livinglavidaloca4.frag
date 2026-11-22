#pragma header

precision mediump float;

uniform float u_time;

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
    vec2 uv = openfl_TextureCoordv;
    
    vec4 texColor = flixel_texture2D(bitmap, uv);
    vec2 dummyUV = uv + (texColor.rg * 0.000001);

    float t = u_time;

    vec2 staticUV = dummyUV;
    staticUV.x *= 320.0;
    staticUV.y *= 240.0;
    staticUV.x += t * 25.0;
    float staticNoise = rand(floor(staticUV));

    vec2 bandUV = vec2(dummyUV.x * 3.0, dummyUV.y * 16.0 + t * 0.8);
    float bands = noise(bandUV);

    vec2 cloudUV = vec2(dummyUV.x * 2.0, dummyUV.y * 7.0 - t * 0.35);
    float clouds = noise(cloudUV);

    float horizontalNoise = noise(vec2(dummyUV.y * 90.0, t * 1.5));
    float displacement = (horizontalNoise - 0.5) * 0.035;
    vec2 distortedUV = dummyUV;
    distortedUV.x += displacement;

    float grain = rand(floor(distortedUV * vec2(420.0, 280.0)) + floor(t * 8.0));

    float signal = staticNoise * 0.58 + bands * 0.25 + clouds * 0.17;
    signal = signal * 0.65 + grain * 0.35;

    float centerGlow = 1.0 - length((dummyUV - vec2(0.5, 0.42)) * vec2(1.0, 1.8));
    centerGlow = clamp(centerGlow, 0.0, 1.0);
    centerGlow *= centerGlow;

    float brightBand = noise(vec2(dummyUV.x * 2.0, dummyUV.y * 5.0 - t * 0.15));
    brightBand = smoothstep(0.45, 0.8, brightBand);

    signal += centerGlow * 0.30;
    signal += brightBand * 0.08;

    float scan = sin(dummyUV.y * 900.0 + t * 18.0) * 0.07;
    signal += scan;

    float interference = sin(dummyUV.y * 90.0 + t * 5.0);
    interference = smoothstep(0.75, 1.0, interference);
    signal += interference * 0.08;

    float darkLines = smoothstep(0.92, 1.0, sin(dummyUV.y * 180.0 - t * 3.0));
    signal -= darkLines * 0.12;

    signal = clamp(signal, 0.0, 1.0);
    signal = smoothstep(0.12, 0.88, signal);

    vec3 darkColor = vec3(0.20, 0.23, 0.24);
    vec3 lightColor = vec3(0.88, 0.91, 0.90);
    vec3 finalColor = mix(darkColor, lightColor, signal);

    float rgbNoise = rand(floor(dummyUV * vec2(180.0, 60.0)) + floor(t * 4.0));
    finalColor.r += (rgbNoise - 0.5) * 0.025;
    finalColor.b += (rgbNoise - 0.5) * 0.035;

    gl_FragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}