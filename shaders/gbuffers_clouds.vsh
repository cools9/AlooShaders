#version 330 compatibility

uniform float frameTimeCounter;

out vec2 texcoord;
out vec4 glcolor;
out vec3 worldPos;
out vec2 cellUV; // position within this cloud cell, -1 to 1 on both axes

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x)
         + (c - a) * u.y * (1.0 - u.x)
         + (d - b) * u.x * u.y;
}

void main()
{
    vec4 pos = gl_Vertex;

    const float cellSize = 12.0; // match to your cloud cell size — adjust if circles look wrong size

    // -1 to 1 across each cell — this is what lets the fragment shader fake curvature
    vec2 localPos = mod(pos.xz, cellSize) - (cellSize * 0.5);
    cellUV = localPos / (cellSize * 0.5);

    // keep a subtle large-scale puff for overall shape variation — small now, most
    // of the "roundness" comes from the fragment shader trick, not vertex displacement
    float puff =
        sin(pos.x * 0.006) *
        cos(pos.z * 0.006);
    puff *= 4.0;

    pos.y += puff;

    gl_Position = gl_ModelViewProjectionMatrix * pos;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
}