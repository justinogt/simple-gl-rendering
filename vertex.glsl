#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 texCoords;

uniform vec4 color;
uniform mat4 projection;

out vec4 vColor;
out vec2 TexCoords;

void main() {
    gl_Position = projection * vec4(aPos, 1.0, 1.0);
    vColor = color;
    TexCoords = texCoords;
}