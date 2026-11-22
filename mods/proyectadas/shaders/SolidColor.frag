
#pragma header

uniform vec3 tintColor;

void main()
{
    vec4 pixel = flixel_texture2D(bitmap, openfl_TextureCoordv);

    gl_FragColor = vec4(
        tintColor * pixel.a,
        pixel.a
    );
}
