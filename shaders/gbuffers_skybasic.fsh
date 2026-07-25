#version 330 compatibility

uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float worldTime;
in vec3 worldPos; // or however your vsh passes position — need to check
layout(location = 0) out vec4 color;

void main() {
    float height = normalize(worldPos).y; // how high up we're looking
    vec3 horizonColor = fogColor;
    vec3 zenithColor = skyColor;
    vec3 sky = mix(horizonColor, zenithColor, clamp(height, 0.0, 1.0));
    color = vec4(sky, 1.0);
}
