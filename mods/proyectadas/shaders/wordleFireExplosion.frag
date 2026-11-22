#pragma header

uniform float explosionAge;
uniform float explosionSeed;
uniform float explosionScale;

float hash11(float value) {
    value = fract(value * 0.1031);
    value *= value + 33.33;
    value *= value + value;
    return fract(value);
}

float hash21(vec2 point) {
    point = fract(point * vec2(123.34, 456.21));
    point += dot(point, point + 45.32);
    return fract(point.x * point.y);
}

float valueNoise(vec2 point) {
    vec2 cell = floor(point);
    vec2 local = fract(point);
    local = local * local * (3.0 - 2.0 * local);

    float a = hash21(cell);
    float b = hash21(cell + vec2(1.0, 0.0));
    float c = hash21(cell + vec2(0.0, 1.0));
    float d = hash21(cell + vec2(1.0, 1.0));
    return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

float fireNoise(vec2 point) {
    float noise = valueNoise(point) * 0.57;
    noise += valueNoise(point * 2.03 + 19.7) * 0.29;
    noise += valueNoise(point * 4.11 + 47.2) * 0.14;
    return noise;
}

float cloudBlob(vec2 point, float radius, float progress, float index) {
    float angle = hash11(explosionSeed * 1.31 + index * 9.73) * 6.2831853;
    float travel = 0.22 + hash11(explosionSeed * 2.17 + index * 4.91) * 0.43;
    vec2 direction = vec2(cos(angle), sin(angle));
    vec2 center = direction * radius * travel;
    center.y -= radius * progress * (0.04 + hash11(index + explosionSeed) * 0.13);

    float size = radius * (0.34 + hash11(explosionSeed * 0.73 + index * 7.17) * 0.22);
    float distanceToBlob = length(point - center);
    return 1.0 - smoothstep(size * 0.56, size, distanceToBlob);
}

float flameTongue(vec2 point, float radius, float progress, float index) {
    float tongueAngle = hash11(explosionSeed * 3.11 + index * 12.41) * 6.2831853;
    vec2 direction = vec2(cos(tongueAngle), sin(tongueAngle));
    vec2 normal = vec2(-direction.y, direction.x);

    float along = dot(point, direction);
    float tongueLength = radius * (0.72 + hash11(explosionSeed + index * 5.37) * 0.83);
    float along01 = clamp(along / max(tongueLength, 0.001), 0.0, 1.0);
    float tongueWidth = radius * (0.026 + hash11(explosionSeed * 0.91 + index * 8.13) * 0.070);
    tongueWidth *= 1.0 - along01 * 0.76;

    float bend = sin(along01 * (5.0 + hash11(index) * 7.0) + explosionSeed + progress * 9.0);
    bend *= tongueWidth * (0.35 + along01 * 0.85);
    float sideways = abs(dot(point, normal) - bend);
    float taperedRay = 1.0 - smoothstep(tongueWidth * 0.42, tongueWidth, sideways);
    float startMask = smoothstep(0.0, radius * 0.20, along);
    float tipMask = 1.0 - smoothstep(tongueLength * 0.73, tongueLength, along);
    return taperedRay * startMask * tipMask;
}

void main() {
    vec2 uv = openfl_TextureCoordv.xy;
    vec4 source = flixel_texture2D(bitmap, uv);
    float aspect = openfl_TextureSize.x / openfl_TextureSize.y;

    vec2 point = uv - vec2(0.5);
    point.x *= aspect;
    float distanceFromCenter = length(point);
    float angle = atan(point.y, point.x);

    float progress = clamp(explosionAge / 0.62, 0.0, 1.0);
    float attack = smoothstep(0.0, 0.012, explosionAge);
    float fade = 1.0 - smoothstep(0.88, 1.0, progress);
    float easedProgress = 1.0 - pow(1.0 - progress, 4.0);
    float radius = (0.015 + easedProgress * 1.42) * explosionScale;

    vec2 noisePosition = vec2(
        angle * 2.25 + explosionSeed,
        distanceFromCenter * 31.0 - explosionAge * 5.2
    );
    float turbulence = fireNoise(noisePosition) - 0.5;
    float ripples = sin(angle * 7.0 + explosionSeed * 2.0) * 0.12;
    ripples += sin(angle * 15.0 - explosionSeed * 1.3) * 0.065;
    ripples += sin(angle * 29.0 + explosionSeed * 0.7) * 0.030;
    float warpedDistance = distanceFromCenter * (1.0 - turbulence * 0.72 - ripples);
    float centerBody = 1.0 - smoothstep(radius * 0.44, radius, warpedDistance);

    float lobes = 0.0;
    lobes += cloudBlob(point, radius, progress, 1.0);
    lobes += cloudBlob(point, radius, progress, 2.0);
    lobes += cloudBlob(point, radius, progress, 3.0);
    lobes += cloudBlob(point, radius, progress, 4.0);
    lobes += cloudBlob(point, radius, progress, 5.0);
    lobes += cloudBlob(point, radius, progress, 6.0);
    lobes += cloudBlob(point, radius, progress, 7.0);
    lobes += cloudBlob(point, radius, progress, 8.0);

    float tongues = 0.0;
    tongues += flameTongue(point, radius, progress, 1.0);
    tongues += flameTongue(point, radius, progress, 2.0);
    tongues += flameTongue(point, radius, progress, 3.0);
    tongues += flameTongue(point, radius, progress, 4.0);
    tongues += flameTongue(point, radius, progress, 5.0);
    tongues += flameTongue(point, radius, progress, 6.0);
    tongues += flameTongue(point, radius, progress, 7.0);
    tongues += flameTongue(point, radius, progress, 8.0);
    tongues += flameTongue(point, radius, progress, 9.0);
    tongues += flameTongue(point, radius, progress, 10.0);

    float density = clamp(centerBody * 0.62 + lobes * 0.32 + tongues * 0.58, 0.0, 1.0);
    float flameMask = smoothstep(0.035, 0.28, density);

    float centerFadeProgress = smoothstep(0.10, 0.78, progress);
    float innerRadius = radius * (0.10 + centerFadeProgress * 0.72);
    float outsideInnerRadius = smoothstep(innerRadius * 0.68, innerRadius, warpedDistance);
    float centerReveal = mix(1.0, outsideInnerRadius, centerFadeProgress);
    flameMask *= centerReveal;

    vec2 scaledPoint = point / max(radius, 0.018);
    float coarseTexture = fireNoise(scaledPoint * 5.2 + vec2(explosionSeed, -explosionAge * 8.0));
    float fineTexture = fireNoise(scaledPoint * 13.0 + vec2(-explosionSeed * 0.7, -explosionAge * 15.0));
    float flameTexture = clamp(coarseTexture * 0.68 + fineTexture * 0.32, 0.0, 1.0);
    float textureOpacity = smoothstep(0.16, 0.76, flameTexture + density * 0.30);
    flameMask *= mix(0.24, 1.0, textureOpacity);

    float orangeLayer = smoothstep(0.25, 0.61, density);
    float yellowLayer = smoothstep(0.50, 0.82, density);
    float whiteCore = smoothstep(0.77, 0.98, density);

    vec3 fireColor = vec3(0.56, 0.018, 0.001);
    fireColor = mix(fireColor, vec3(1.0, 0.16, 0.006), orangeLayer);
    fireColor = mix(fireColor, vec3(1.0, 0.66, 0.025), yellowLayer);
    fireColor = mix(fireColor, vec3(1.0, 0.95, 0.56), whiteCore);
    fireColor = mix(vec3(0.15, 0.004, 0.001), fireColor, 0.38 + flameTexture * 0.62);

    float ringRadius = radius * 1.12;
    float ringWidth = max(0.0025, radius * 0.026);
    float shockwave = 1.0 - smoothstep(0.0, ringWidth, abs(warpedDistance - ringRadius));
    shockwave *= (1.0 - smoothstep(0.15, 0.64, progress)) * attack;

    float sparkRays = pow(max(0.0, sin(angle * 23.0 + explosionSeed * 3.7)), 38.0);
    sparkRays += pow(max(0.0, sin(angle * 37.0 - explosionSeed * 2.1)), 52.0) * 0.72;
    float sparkBand = smoothstep(radius * 0.68, radius * 0.94, distanceFromCenter);
    sparkBand *= 1.0 - smoothstep(radius * 1.05, radius * 2.15, distanceFromCenter);
    float sparks = sparkRays * sparkBand * attack * (1.0 - progress);

    float fireOpacity = flameMask * attack * fade * 0.98;
    vec3 color = mix(source.rgb, fireColor, fireOpacity);
    color += vec3(1.0, 0.39, 0.015) * sparks * 0.88;
    color += vec3(1.0, 0.55, 0.12) * shockwave * 0.42;

    gl_FragColor = vec4(color, source.a);
}
