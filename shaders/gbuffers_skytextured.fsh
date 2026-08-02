#version 330 compatibility

uniform sampler2D gtexture;
in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
    color = texture(gtexture, texcoord) * glcolor;
    vec2 centered = texcoord - vec2(0.5);
    float dist = length(centered);


    float circleMask = 1.0 - smoothstep(0.45, 0.5, dist);
    color.a *= circleMask;

    if (color.a < 0.1)
        discard;
}