#version 330 compatibility
uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform float alphaTestRef = 0.1;
uniform float frameTimeCounter;
flat in int blockId;
in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 tangent;
in vec3 bitangent;

/* RENDERTARGETS: 0,1,2,3,4 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 materialData;
layout(location = 4) out vec4 pbrData; // r: roughness, g: F0-encoded-raw, b: metallic, a: emission

void main() {
    color = texture(gtexture, texcoord) * glcolor;
    color *= texture(lightmap, lmcoord);
    if (color.a < alphaTestRef)
        discard;

    lightmapData = vec4(lmcoord, 0.0, 1.0);

    vec3 N = normal;
    materialData = vec4(0.0);

    if (blockId == 101)
    {
        float t = frameTimeCounter;
        vec2 uv = texcoord * 32.0;
        vec2 scrollA = uv * 0.05 + vec2(t * 0.6, t * 0.3);
        vec2 scrollB = uv * 0.13 - vec2(t * 0.25, t * 0.45);
        float noiseA = texture(noisetex, fract(scrollA)).r;
        float noiseB = texture(noisetex, fract(scrollB)).r;
        float waveX = sin(uv.x * 1.7 + t * 2.0 + noiseA * 6.2831) + (noiseB - 0.5) * 2.0;
        float waveZ = cos(uv.y * 1.5 + t * 2.2 + noiseB * 6.2831) + (noiseA - 0.5) * 2.0;
        N = normalize(vec3(waveX * 0.15, 1.0, waveZ * 0.15));
        materialData = vec4(1.0, 0.0, 0.0, 1.0);
    }

    // normal map: perturb N using the tangent-space normal texture, real texcoord this time
    vec3 texNormal = texture(normals, texcoord).rgb * 2.0 - 1.0;
    if (texNormal != vec3(-1.0)) {
        //vec3 texNormal = texture(normals, texcoord).rgb * 2.0 - 1.0;
        mat3 TBN = mat3(normalize(tangent), normalize(bitangent), normalize(N));
        N = normalize(TBN * texNormal);
    }

    // sample specular here — correct UV space — pass raw channels through, decode in composite
    vec4 specularTex = texture(specular, texcoord);
    pbrData = specularTex; // r=smoothness, g=F0/metal-index, b=porosity/SSS, a=emission — raw, per labPBR spec

    encodedNormal = vec4(N * 0.5 + 0.5, 1.0);
}