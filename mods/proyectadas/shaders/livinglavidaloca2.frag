#pragma header

uniform float u_time;

const float TAU = 6.28318530718;

float hash11(float value)
{
    return fract(sin(value * 91.3458) * 47453.5453);
}

vec3 redOrangePalette(float phase)
{
    float wave = 0.5 + 0.5 * sin(TAU * phase);
    float hotCore = 0.5 + 0.5 * sin(TAU * (phase + 0.22));
    vec3 deepRed = vec3(0.540, 0.025, 0.005);
    vec3 hotRed = vec3(1.000, 0.110, 0.010);
    vec3 orange = vec3(1.000, 0.620, 0.060);
    return mix(mix(deepRed, hotRed, wave), orange, hotCore * 0.70);
}

float lavaField(vec2 point, float time)
{
    float field = 0.0;

    for (int index = 0; index < 12; index++)
    {
        float id = float(index);
        float randomA = hash11(id + 4.23);
        float speed = 0.090 + randomA * 0.080;
        float travel = mod(id * 0.225 + time * speed, 2.76);

        vec2 center;
        center.y = -1.38 + travel;
        float column = mod(id, 6.0);
        center.x = -1.55 + column * 0.62;
        center.x += cos(time * (0.31 + randomA * 0.27) + id * 1.73) * 0.36;
        center.x += sin(center.y * 3.3 + time * 0.30) * 0.14;

        float radius = 0.230 + hash11(id + 32.4) * 0.190;
        vec2 delta = point - center;
        delta.y *= 0.70 + 0.13 * cos(time * 0.51 + id * 1.7);
        delta.x += sin(delta.y * 5.5 - time * 0.78 + id) * 0.043;

        field += exp(-dot(delta, delta) / (radius * radius) * 1.20);
    }

    float liquidPulse = sin(point.y * 5.2 - time * 0.28 + sin(point.x * 3.7));
    return field * (0.95 + liquidPulse * 0.05);
}

void main()
{
    vec2 uv = openfl_TextureCoordv.xy;
    float aspect = openfl_TextureSize.x / openfl_TextureSize.y;
    vec2 point = uv * 2.0 - 1.0;
    point.x *= aspect;

    float time = u_time;
    point.x += cos(point.y * 3.0 - time * 0.46) * 0.110;
    point.y += sin(point.x * 2.3 + time * 0.33) * 0.058;

    float field = lavaField(point, time);
    float halo = smoothstep(0.018, 0.065, field);
    float body = smoothstep(0.115, 0.165, field);
    float core = smoothstep(0.41, 0.48, field);
    float rim = smoothstep(0.047, 0.085, field) - smoothstep(0.138, 0.182, field);

    vec3 backgroundA = vec3(0.650, 0.085, 0.006);
    vec3 backgroundB = vec3(0.965, 0.310, 0.018);
    float backgroundWave = 0.5 + 0.5 * sin(point.x * 4.0 + sin(point.y * 5.5 + time * 1.0) * 2.1 - time * 0.68);
    float crossingWave = 0.5 + 0.5 * sin(point.y * 4.6 + sin(point.x * 3.2 - time * 0.74) * 1.9);
    float backgroundPoster = floor(clamp((backgroundWave + crossingWave) * 0.5, 0.0, 0.999) * 4.0) / 3.0;
    vec3 backgroundBand = redOrangePalette(time * 0.065 - point.y * 0.12 + backgroundPoster * 0.18);
    vec3 color = mix(backgroundA, backgroundB, backgroundPoster);
    color = mix(color, backgroundBand, 0.36);

    float colorPhase = time * 0.082 - point.y * 0.16 + field * 0.092;
    float internalSwirl = 0.5 + 0.5 * cos(field * 4.5 - point.y * 10.0 + time * 1.45);
    vec3 outerColor = redOrangePalette(colorPhase);
    vec3 innerColor = redOrangePalette(colorPhase + 0.20 + internalSwirl * 0.15);
    float cartoonBand = floor(internalSwirl * 2.999) / 2.0;
    vec3 lavaColor = mix(outerColor, innerColor, cartoonBand);

    vec3 flatBubble = mix(lavaColor, innerColor, core);
    color = mix(color, outerColor, halo * 0.34);
    color = mix(color, flatBubble, body);

    float contourBand = step(0.5, fract(field * 3.7 + time * 0.46 - point.y * 0.9));
    vec3 contourColor = redOrangePalette(colorPhase + 0.36);
    color = mix(color, contourColor, contourBand * body * 0.36);
    color = mix(color, vec3(1.0, 0.635, 0.075), rim);

    float cartoonShine = step(0.69, 0.5 + 0.5 * sin(point.x * 13.0 + point.y * 8.0 - time * 2.3));
    color = mix(color, vec3(1.0, 0.860, 0.220), cartoonShine * body * 0.20);

    float confetti = step(0.93, 0.5 + 0.5 * sin(point.x * 12.0 - time * 1.1) * sin(point.y * 11.0 + time * 1.4));
    color = mix(color, vec3(1.0, 0.540, 0.055), confetti * (1.0 - body) * 0.18);

    float sourceAlpha = flixel_texture2D(bitmap, uv).a;
    gl_FragColor = vec4(max(color, vec3(0.0)), sourceAlpha);
}
