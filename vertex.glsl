#version 330 core
layout (location = 0) in vec2 aPos;

uniform vec4 color = vec4(1, 1, 1, 1);
uniform vec2 scale = vec2(1, 1);
uniform vec2 offset = vec2(0, 0);
uniform float zIndex = 0;

out vec4 vColor;

void main() {
    vec2 scaled = aPos * scale + offset;
    gl_Position = vec4(scaled, zIndex, 1.0);
    vColor = color;
}