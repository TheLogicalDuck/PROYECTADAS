#pragma header

uniform float u_time;

const float TAU = 6.28318530718;

vec3 purpleWaterPalette(float phase)
{
    float wave = 0.5 + 0.5 * sin(TAU * phase);
    float secondWave = 0.5 + 0.5 * sin(TAU * (phase + 0.31));
    vec3 softPlum = vec3(0.310, 0.245, 0.405);
    vec3 lavender = vec3(0.535, 0.435, 0.645);
    vec3 paleViolet = vec3(0.790, 0.700, 0.850);
    return mix(mix(softPlum, lavender, wave), paleViolet, secondWave * 0.52);
}

float layeredWater(vec2 point, float time)
{
    float broadWave = sin(
        point.y * 5.2
        + sin(point.x * 2.4 + time * 0.52) * 1.55
        - time * 0.92
    );
    float crossingWave = sin(
        point.x * 3.4
        + sin(point.y * 3.1 - time * 0.38) * 1.25
        + time * 0.58
    );
    float rippleWave = sin(
        (point.x + point.y) * 8.5
        + sin(point.x * 4.0 - time * 0.70)
        - time * 0.36
    );
    return broadWave * 0.56 + crossingWave * 0.29 + rippleWave * 0.15;
}

void main()
{
    vec2 uv = openfl_TextureCoordv.xy;
    float aspect = openfl_TextureSize.x / openfl_TextureSize.y;
    vec2 point = uv * 2.0 - 1.0;
    point.x *= aspect;

    float time = u_time;
    point.x += sin(point.y * 3.0 + time * 0.45) * 0.16;
    point.y += sin(point.x * 2.2 - time * 0.34) * 0.09;

    float water = layeredWater(point, time);
    float waterValue = clamp(water * 0.5 + 0.5, 0.0, 0.999);
    float posterizedWater = floor(waterValue * 5.0) / 4.0;

    float colorPhase = time * 0.045 + point.x * 0.045 - point.y * 0.085;
    vec3 deepWater = vec3(0.285, 0.235, 0.380);
    vec3 lightWater = vec3(0.735, 0.650, 0.810);
    vec3 color = mix(deepWater, lightWater, posterizedWater);
    color = mix(color, purpleWaterPalette(colorPhase + posterizedWater * 0.17), 0.43);

    float mainCrest = sin(
        point.y * 6.4
        + sin(point.x * 2.8 + time * 0.70) * 1.65
        - time * 1.10
    );
    float crossingCrest = sin(
        point.x * 5.0
        - sin(point.y * 3.5 - time * 0.55) * 1.30
        + time * 0.74
    );
    float whiteCrestA = 1.0 - smoothstep(0.025, 0.15, abs(mainCrest));
    float whiteCrestB = 1.0 - smoothstep(0.018, 0.11, abs(crossingCrest));
    float whiteCaustics = clamp(whiteCrestA + whiteCrestB * 0.72, 0.0, 1.0);
    color = mix(color, vec3(0.965, 0.950, 1.000), whiteCaustics * 0.78);

    float softGlow = 0.5 + 0.5 * sin(point.x * 7.0 + point.y * 5.0 - time * 0.9);
    softGlow = smoothstep(0.72, 0.96, softGlow);
    color = mix(color, vec3(0.875, 0.830, 0.925), softGlow * 0.20);

    float sourceAlpha = flixel_texture2D(bitmap, uv).a;
    gl_FragColor = vec4(max(color, vec3(0.0)), sourceAlpha);
}
