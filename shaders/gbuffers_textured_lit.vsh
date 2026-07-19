#version 330 compatibility

in vec2 mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;

flat out int blockId;

uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;

void main() {

    vec4 position = gl_Vertex;

    // Pass block ID to fragment shader
    blockId = int(mc_Entity.x);

    vec3 N = gl_Normal;

    // Leaves
    if (blockId == 100) {

        float wind =
            sin(position.x * 0.4 + frameTimeCounter * 2.0) +
            cos(position.z * 0.3 + frameTimeCounter * 1.8);

        wind *= 0.03;

        position.x += wind;
        position.z += wind * 0.5;
    }

    // Water
    else if (blockId == 101) {

        float wave = 0.0;

        wave += sin(position.x * 0.8 + frameTimeCounter * 2.0);
        wave += cos(position.z * 0.6 + frameTimeCounter * 1.5);
        wave += sin((position.x + position.z) * 0.4 + frameTimeCounter * 2.8);

        wave *= 0.015;

        position.y += wave;

        // Approximate animated normal
        float dx =
            cos(position.x * 0.8 + frameTimeCounter * 2.0) * 0.8 +
            cos((position.x + position.z) * 0.4 + frameTimeCounter * 2.8) * 0.4;

        float dz =
            -sin(position.z * 0.6 + frameTimeCounter * 1.5) * 0.6 +
            cos((position.x + position.z) * 0.4 + frameTimeCounter * 2.8) * 0.4;

        N = normalize(vec3(-dx * 0.02, 1.0, -dz * 0.02));
    }

    gl_Position = gl_ModelViewProjectionMatrix * position;

    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;

    normal = gl_NormalMatrix * N;
    normal = mat3(gbufferModelViewInverse) * normal;
}
