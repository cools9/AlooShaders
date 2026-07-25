#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;
uniform float frameTimeCounter;
uniform sampler2D noisetex;
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

    // use world-space-ish position instead of pure texcoord so tiling isn't tied
    // to the texture's UV repeat interval
    vec2 uv = texcoord * 32.0;

    // scroll two noise samples at different speeds/scales and combine —
    // breaks the phase-locked periodicity of pure sine sums
    vec2 scrollA = uv * 0.05 + vec2(t * 0.6, t * 0.3);
    vec2 scrollB = uv * 0.13 - vec2(t * 0.25, t * 0.45);

    float noiseA = texture(noisetex, fract(scrollA)).r;
    float noiseB = texture(noisetex, fract(scrollB)).r;

    // still keep a couple sine terms for directional "wave" character,
    // but drive their phase/amplitude off noise instead of pure time
    float waveX =
          sin(uv.x * 1.7 + t * 2.0 + noiseA * 6.2831)
        + (noiseB - 0.5) * 2.0;
    float waveZ =
          cos(uv.y * 1.5 + t * 2.2 + noiseB * 6.2831)
        + (noiseA - 0.5) * 2.0;

    N = normalize(vec3(
        waveX * 0.15,
        1.0,
        waveZ * 0.15
    ));
    materialData = vec4(1.0,0.0,0.0,1.0);
}    else
    {
        materialData = vec4(0.0);
    }

    encodedNormal = vec4(N * 0.5 + 0.5,1.0);
}

