#pragma header

uniform float time;
uniform float bloomStrength;
uniform float lightningStrength;
uniform float worldLightningStrength;

uniform vec4 opponentEyes;
uniform vec4 playerEyes;

float hash11(float value) {
    value = fract(value * 0.1031);
    value *= value + 33.33;
    value *= value + value;
    return fract(value);
}

float jaggedNoise(float value, float seed) {
    float cell = floor(value);
    float local = fract(value);
    return mix(hash11(cell + seed), hash11(cell + seed + 1.0), local);
}

float boltSegment(vec2 point, vec2 start, vec2 finish, float seed, float width) {
    vec2 axis = finish - start;
    float axisLength = max(length(axis), 0.001);
    vec2 direction = axis / axisLength;
    vec2 normal = vec2(-direction.y, direction.x);

    float rawAlong = dot(point - start, direction) / axisLength;
    float along = clamp(rawAlong, 0.0, 1.0);
    vec2 center = mix(start, finish, along);

    float coarse = jaggedNoise(along * 11.0, seed) - 0.5;
    float detail = jaggedNoise(along * 29.0, seed * 3.17) - 0.5;
    float pinnedEnds = 4.0 * along * (1.0 - along);
    float displacement = (coarse * 0.082 + detail * 0.021) * pinnedEnds;
    float distanceToChannel = abs(dot(point - center, normal) - displacement);

    float inside = step(0.0, rawAlong) * step(rawAlong, 1.0);
    float core = 1.0 - smoothstep(width, width * 3.1, distanceToChannel);
    float glow = 1.0 - smoothstep(width * 3.0, width * 17.0, distanceToChannel);
    float farGlow = 1.0 - smoothstep(width * 12.0, width * 46.0, distanceToChannel);

    return (core * 1.85 + glow * 0.72 + farGlow * 0.18) * inside;
}


float boltNetwork(vec2 point, vec2 start, vec2 finish, float seed) {
    vec2 direction = normalize(finish - start);
    vec2 normal = vec2(-direction.y, direction.x);
    float side = step(0.5, hash11(seed * 4.3)) * 2.0 - 1.0;

    vec2 forkA = finish + normalize(direction * 0.20 + normal * side) * (0.16 + hash11(seed + 4.0) * 0.16);
    vec2 forkB = finish + normalize(direction * 0.32 - normal * side) * (0.12 + hash11(seed + 8.0) * 0.13);
    vec2 twigA = forkA + normalize(direction * 0.10 - normal * side) * (0.07 + hash11(seed + 11.0) * 0.08);
    vec2 twigB = forkB + normalize(direction * 0.16 + normal * side) * (0.06 + hash11(seed + 15.0) * 0.07);

    float energy = boltSegment(point, start, finish, seed, 0.0026);
    energy += boltSegment(point, finish, forkA, seed + 17.0, 0.00175) * 0.88;
    energy += boltSegment(point, finish, forkB, seed + 29.0, 0.00145) * 0.78;
    energy += boltSegment(point, forkA, twigA, seed + 41.0, 0.00095) * 0.62;
    energy += boltSegment(point, forkB, twigB, seed + 53.0, 0.00080) * 0.56;

    vec2 middle = mix(start, finish, 0.62);
    vec2 middleTip = middle + normalize(direction * 0.15 + normal * -side) * (0.10 + hash11(seed + 61.0) * 0.11);
    energy += boltSegment(point, middle, middleTip, seed + 67.0, 0.00115) * 0.66;

    return energy;
}

float eyeArc(vec2 point, vec2 eye, float directionSign, float seed) {
    float verticalAim = (hash11(seed + 3.0) - 0.5) * 0.58;
    vec2 finish = eye + vec2(directionSign * (0.20 + hash11(seed + 7.0) * 0.30), verticalAim);
    vec2 axis = normalize(finish - eye);
    vec2 normal = vec2(-axis.y, axis.x);
    float side = step(0.5, hash11(seed + 9.0)) * 2.0 - 1.0;
    vec2 branch = finish + normalize(axis * 0.20 + normal * side) * (0.10 + hash11(seed + 13.0) * 0.12);
    vec2 twig = branch + normalize(axis * 0.08 - normal * side) * (0.055 + hash11(seed + 19.0) * 0.07);

    float energy = boltSegment(point, eye, finish, seed, 0.0024);
    energy += boltSegment(point, finish, branch, seed + 23.0, 0.00135) * 0.86;
    energy += boltSegment(point, branch, twig, seed + 31.0, 0.00080) * 0.58;
    return energy;
}

float eyeElectricity(vec2 point, vec4 eyeData, float seedOffset) {
    float aspect = openfl_TextureSize.x / openfl_TextureSize.y;
    vec2 center = vec2((eyeData.x - 0.5) * aspect, eyeData.y - 0.5);
    float spacing = eyeData.z * aspect;
    vec2 leftEye = center - vec2(spacing, 0.0);
    vec2 rightEye = center + vec2(spacing, 0.0);

    float leftDistance = length(point - leftEye);
    float rightDistance = length(point - rightEye);
    float eyeGlow = 1.0 - smoothstep(0.006, 0.074, min(leftDistance, rightDistance));
    float eyeCore = 1.0 - smoothstep(0.002, 0.015, min(leftDistance, rightDistance));

    float strikeId = floor(time * 8.0) + seedOffset;
    float energy = eyeGlow * 1.15 + eyeCore * 2.5;
    energy += eyeArc(point, leftEye, -1.0, strikeId + 211.0);
    energy += eyeArc(point, rightEye, 1.0, strikeId + 307.0);
    return energy * eyeData.w;
}

vec3 sceneBloom(vec2 uv, vec2 texel, vec3 centerColor) {
    vec3 glow = centerColor * 0.20;
    glow += flixel_texture2D(bitmap, uv + vec2(texel.x * 4.0, 0.0)).rgb * 0.11;
    glow += flixel_texture2D(bitmap, uv - vec2(texel.x * 4.0, 0.0)).rgb * 0.11;
    glow += flixel_texture2D(bitmap, uv + vec2(0.0, texel.y * 4.0)).rgb * 0.11;
    glow += flixel_texture2D(bitmap, uv - vec2(0.0, texel.y * 4.0)).rgb * 0.11;
    glow += flixel_texture2D(bitmap, uv + texel * vec2(3.0, 3.0)).rgb * 0.09;
    glow += flixel_texture2D(bitmap, uv + texel * vec2(-3.0, 3.0)).rgb * 0.09;
    glow += flixel_texture2D(bitmap, uv + texel * vec2(3.0, -3.0)).rgb * 0.09;
    glow += flixel_texture2D(bitmap, uv - texel * vec2(3.0, 3.0)).rgb * 0.09;
    return max(glow - vec3(0.24), vec3(0.0));
}

void main() {
    vec2 uv = openfl_TextureCoordv.xy;
    vec2 texel = 1.0 / openfl_TextureSize.xy;
    vec4 source = flixel_texture2D(bitmap, uv);
    float aspect = openfl_TextureSize.x / openfl_TextureSize.y;
    vec2 point = vec2((uv.x - 0.5) * aspect, uv.y - 0.5);

    vec3 color = source.rgb;
    color += sceneBloom(uv, texel, source.rgb) * bloomStrength;

    float strikeClock = time * 8.0;
    float strikeId = floor(strikeClock);
    float strikeAge = fract(strikeClock);
    float flash = 0.82 + pow(1.0 - strikeAge, 7.0) * 1.55;
    flash *= 0.82 + hash11(strikeId * 8.7) * 0.42;

    vec2 topStart = vec2((hash11(strikeId + 1.0) - 0.5) * aspect, -0.56);
    vec2 topFinish = vec2((hash11(strikeId + 2.0) - 0.5) * aspect * 0.80, -0.02 + hash11(strikeId + 3.0) * 0.40);
    vec2 leftStart = vec2(-aspect * 0.56, hash11(strikeId + 5.0) - 0.5);
    vec2 leftFinish = vec2(-0.15 + hash11(strikeId + 6.0) * 0.62, (hash11(strikeId + 7.0) - 0.5) * 0.72);
    vec2 bottomStart = vec2((hash11(strikeId + 9.0) - 0.5) * aspect, 0.56);
    vec2 bottomFinish = vec2((hash11(strikeId + 10.0) - 0.5) * aspect * 0.76, -0.36 + hash11(strikeId + 12.0) * 0.55);

    float worldLightning = 0.0;
    worldLightning += boltNetwork(point, topStart, topFinish, strikeId + 13.0);
    worldLightning += boltNetwork(point, leftStart, leftFinish, strikeId + 79.0) * 0.92;
    worldLightning += boltNetwork(point, bottomStart, bottomFinish, strikeId + 137.0) * 0.96;

    float opponentLightning = eyeElectricity(point, opponentEyes, 211.0) * 1.34 * flash;
    float playerLightning = eyeElectricity(point, playerEyes, 409.0) * 1.34 * flash;
    worldLightning *= flash;

    float colorWave = 0.5 + 0.5 * sin(time * 5.2 + uv.y * 13.0 + strikeId);
    vec3 electricColor = mix(vec3(0.20, 0.62, 1.0), vec3(0.74, 0.30, 1.0), colorWave);
    float worldStrength = lightningStrength * worldLightningStrength;
    color += electricColor * worldLightning * worldStrength;
    color += vec3(0.80, 0.92, 1.0) * worldLightning * worldLightning * 0.32 * worldStrength;

    vec3 playerColor = mix(vec3(0.025, 0.95, 0.16), vec3(0.62, 1.0, 0.04), colorWave);
    color += playerColor * playerLightning * lightningStrength;
    color += vec3(0.72, 1.0, 0.34) * playerLightning * playerLightning * 0.32 * lightningStrength;

    vec3 opponentColor = mix(vec3(1.0, 0.035, 0.11), vec3(0.67, 0.045, 1.0), colorWave);
    color += opponentColor * opponentLightning * lightningStrength;
    color += vec3(1.0, 0.20, 0.48) * opponentLightning * opponentLightning * 0.32 * lightningStrength;

    float exposureFlash = pow(1.0 - strikeAge, 12.0) * 0.22 * worldStrength;
    color += vec3(0.30, 0.48, 0.82) * exposureFlash;

    float wash = 0.5 + 0.5 * sin(time * 1.8 + uv.x * 7.0 - uv.y * 4.0);
    color += mix(vec3(0.018, 0.030, 0.070), vec3(0.055, 0.012, 0.072), wash);

    gl_FragColor = vec4(color, source.a);
}
