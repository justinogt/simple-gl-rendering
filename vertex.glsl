#version 330 core
layout (location = 0) in vec2 aPos;

uniform vec4 color;
uniform mat4 projection;

out vec4 vColor;

void main() {
    gl_Position = projection * vec4(aPos, 1.0, 1.0);
    vColor = color;
}