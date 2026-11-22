#pragma header

uniform vec3 tintColor;

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec4 tex = flixel_texture2D(bitmap, uv);

    gl_FragColor = vec4(tintColor * tex.a, tex.a);
}
