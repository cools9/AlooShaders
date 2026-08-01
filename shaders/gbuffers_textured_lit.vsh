#version 330 compatibility
in vec2 mc_Entity;
in vec4 at_tangent;
out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 tangent;
out vec3 bitangent;
flat out int blockId;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
void main() {
    vec4 position = gl_Vertex;
    blockId = int(mc_Entity.x);
    vec3 N = gl_Normal;

    if (blockId == 100) {
        float wind = sin(position.x * 0.4 + frameTimeCounter * 2.0) + cos(position.z * 0.3 + frameTimeCounter * 1.8);
        wind *= 0.03;
        position.x += wind;
        position.z += wind * 0.5;
    }
    else if (blockId == 101) {
        float t = frameTimeCounter;

        // world-space-ish position so the wave pattern doesn't repeat with UV tiling
        float waveHeight =
              sin(position.x * 0.6 + t * 1.2) * 0.04
            + cos(position.z * 0.5 + t * 1.5) * 0.04
            + sin((position.x + position.z) * 0.3 + t * 0.9) * 0.03;

        position.y += waveHeight;
    }

    gl_Position = gl_ModelViewProjectionMatrix * position;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    normal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * N);
    tangent = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * at_tangent.xyz);
    bitangent = cross(tangent, normal) * at_tangent.w; // DirectX-style handedness, per labPBR
}