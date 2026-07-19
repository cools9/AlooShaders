#version 330 compatibility

in vec2 mc_Entity;
out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;

void main() {
    vec4 position = gl_Vertex;

    int blockId = int(mc_Entity.x);
    if (blockId == 100) {
        float wind =
            sin(position.x * 0.4 + frameTimeCounter * 2.0) +
            cos(position.z * 0.3 + frameTimeCounter * 1.8);

        wind *= 0.03;

        position.x += wind;
        position.z += wind * 0.5;
    } else if (blockId == 101) {
        position.y +=
                sin(position.x * 0.3 + frameTimeCounter * 2.0) * 0.04 +
                cos(position.z * 0.25 + frameTimeCounter * 1.6) * 0.03;
    }

    gl_Position = gl_ModelViewProjectionMatrix * position;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    normal = gl_NormalMatrix * gl_Normal;
    normal = mat3(gbufferModelViewInverse) * normal;
}
