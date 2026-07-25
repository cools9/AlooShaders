#version 330 compatibility

uniform vec3 fogColor;
uniform float far;
in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
    // vanilla passes cloud shape/shading through vertex color alpha
    color = glcolor;

    // softer, fluffier look: reduce harsh opacity, brighten slightly
    color.rgb = mix(color.rgb, vec3(1.0), 0.15);
    color.a *= 0.75;

    // fade clouds into fog color/fog color at distance so edges don't look like a hard cutoff
    // (gl_FragCoord.z-based distance approx since we don't have depth here)
    float fade = clamp(1.0 - gl_FragCoord.z, 0.0, 1.0);
    color.rgb = mix(fogColor, color.rgb, fade);
}
