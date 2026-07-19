#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;
uniform float frameTimeCounter;

flat in int blockId;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 materialData;

void main() {

    color = texture(gtexture, texcoord) * glcolor;
    color *= texture(lightmap, lmcoord);

    if (color.a < alphaTestRef)
        discard;

    lightmapData = vec4(lmcoord, 0.0, 1.0);

    vec3 N = normal;

    if (blockId == 101)
    {
        float t = frameTimeCounter;

        vec2 uv = texcoord * 32.0;

        float waveX =
              sin(uv.x * 1.7 + t * 2.0)
            + sin(uv.y * 2.8 + t * 1.4)
            + sin((uv.x + uv.y) * 1.2 + t * 2.7);

        float waveZ =
              cos(uv.y * 1.5 + t * 2.2)
            + cos(uv.x * 2.5 + t * 1.8)
            + cos((uv.x - uv.y) * 1.3 + t * 2.4);

        N = normalize(vec3(
            waveX * 0.15,
            1.0,
            waveZ * 0.15
        ));

        materialData = vec4(1.0,0.0,0.0,1.0);
    }
    else
    {
        materialData = vec4(0.0);
    }

    encodedNormal = vec4(N * 0.5 + 0.5,1.0);
}
