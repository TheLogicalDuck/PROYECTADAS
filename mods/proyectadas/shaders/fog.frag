#pragma header

precision mediump float;

uniform float u_time;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float fogSpeed;
uniform float maskWidth; // Controla el ancho de la columna vertical izquierda

float rand(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec4 texColor = flixel_texture2D(bitmap, uv);

    float t = u_time * fogSpeed;

    vec2 p1 = uv * vec2(3.0, 2.0) + vec2(sin(t * 0.3) * 0.2, cos(t * 0.2) * 0.2);
    vec2 p2 = uv * vec2(6.0, 4.0) + vec2(cos(t * 0.4) * 0.15, sin(t * 0.3) * 0.15);

    float n1 = noise(p1);
    float n2 = noise(p2);
    float fog = n1 * 0.6 + n2 * 0.4;

    fog = smoothstep(0.30, 0.72, fog);
    float leftMask = 1.0 - smoothstep(0.0, maskWidth, uv.x);

    float bottomMask = (1.0 - smoothstep(0.0, 0.15, 1.0 - uv.y));
    
    float mask = max(leftMask, bottomMask);

    fog *= mask;

    fog = clamp(fog * fogDensity, 0.0, 1.0);
    vec3 finalColor = mix(texColor.rgb, fogColor, fog);

    float finalAlpha = max(texColor.a, fog);

    gl_FragColor = vec4(finalColor, finalAlpha);
}