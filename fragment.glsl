#version 330 core

in vec2 TexCoords;
in  vec4 vColor;

out vec4 FragColor;

uniform sampler2D glyph_texture;

void main() {
    vec4 t = texture(glyph_texture, TexCoords);
    if (t.r > 0) {
        FragColor = vec4(vColor.xyz, t.r);
    } else {
        FragColor = vec4(vColor.xyz, 1);
    }
}