#version 330 compatibility

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;

/* RENDERTARGETS: 0,1,2,3,4 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 materialData;
layout(location = 4) out vec4 pbrData;

void main() {
    color = texture(gtexture, texcoord) * glcolor;
    color *= texture(lightmap, lmcoord);
    if (color.a < alphaTestRef)
        discard;

    lightmapData = vec4(lmcoord, 0.0, 1.0);
    materialData = vec4(0.0);

    float smoothness = 0.35; // slightly rougher than 0.25 — broadens the direct sun highlight a bit more
    float f0 = 0.15;         // raised from 0.06 — stronger baseline reflectivity feeds the new ambient term below
    pbrData = vec4(smoothness, f0, 0.0, 1.0);

    encodedNormal = vec4(normalize(normal) * 0.5 + 0.5, 1.0);
}