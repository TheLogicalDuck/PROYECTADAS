#pragma header

uniform float u_time;

vec3 rand(vec2 uv, float t) {
    float r = fract(sin(dot(uv, vec2(1225.6548, 321.8942))) * 4251.4865 + t);
    float g = fract(sin(dot(uv + 0.1, vec2(1225.6548, 321.8942))) * 4251.4865 + t);
    float b = fract(sin(dot(uv + 0.2, vec2(1225.6548, 321.8942))) * 4251.4865 + t);
    return vec3(r, g, b);
}

void main()
{
    vec2 uv = openfl_TextureCoordv;
    
    // Multiplicamos u_time para controlar la velocidad de la estática
    float t = u_time * 6.0;
    
    // Generamos el color de la estática RGB
    vec3 col = rand(uv, t);
    
    // Respetamos la transparencia (alpha) del sprite original
    vec4 texColor = flixel_texture2D(bitmap, uv);
    
    gl_FragColor = vec4(col, texColor.a);
}