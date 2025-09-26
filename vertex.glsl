#version 330 core
layout (location = 0) in vec2 aPos;

uniform vec4 color;
uniform mat4 projection;
uniform float zIndex = 0;

out vec4 vColor;

void main() {
    gl_Position = projection * vec4(aPos, zIndex, 1.0);
    vColor = color;
}