#version 330 compatibility

#include "/lib/distort.glsl"
#define SHADOW_RANGE 1
#define SHADOW_RADIUS 0.6

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform sampler2D depthtex0;
in vec2 texcoord;
uniform sampler2D shadowtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D colortex3;
uniform sampler2D noisetex;
uniform float viewWidth;
uniform float viewHeight;
uniform int worldTime;
uniform float rainStrength;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

vec4 getNoise(vec2 coord) {
    ivec2 screenCoord = ivec2(coord * vec2(viewWidth, viewHeight));
    ivec2 noiseCoord = screenCoord % 64;
    return texelFetch(noisetex, noiseCoord, 0);
}

vec3 getShadow(vec3 shadowScreenPos){
  float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);

  if(transparentShadow == 1.0){
    return vec3(1.0);
  }

  float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r);

  if(opaqueShadow == 0.0){
    return vec3(0.0);
  }

  vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);
  return shadowColor.rgb * (1.0 - shadowColor.a);
}

vec3 getSoftShadow(vec3 shadowScreenPos, vec2 screenTexcoord) {
    // per-pixel rotation breaks up the fixed-grid PCF pattern into dithered noise
    float noise = getNoise(screenTexcoord).r;
    float theta = noise * radians(360.0);
    mat2 rotation = mat2(cos(theta), -sin(theta), sin(theta), cos(theta));

    vec3 sum = vec3(0.0);

    for (int x = -SHADOW_RANGE; x <= SHADOW_RANGE; x++) {
        for (int y = -SHADOW_RANGE; y <= SHADOW_RANGE; y++) {
            vec2 offset = vec2(x, y) * (SHADOW_RADIUS / float(shadowMapResolution));
            offset = rotation * offset;
            vec3 samplePos = shadowScreenPos;
            samplePos.xy += offset;
            sum += getShadow(samplePos);
        }
    }

    float samples = float((SHADOW_RANGE * 2 + 1) * (SHADOW_RANGE * 2 + 1));
    return sum / samples;
}


void main() {
    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) { color = texture(colortex0, texcoord); return; }

    color = texture(colortex0, texcoord);

    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

    vec3 encodedNormal = texture(colortex2, texcoord).rgb;
    vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
    vec3 lightVector = normalize(shadowLightPosition);
    vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
    float NdotL = clamp(dot(normal, worldLightVector), 0.0, 1.0);

    float normalOffset = mix(0.05, 0.01, NdotL);
    feetPlayerPos += normal * normalOffset;

    vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
    vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
    vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
    vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;

    const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
    const vec3 skylightColor = vec3(0.05, 0.15, 0.3);
    const vec3 sunlightColor = vec3(1.0);
    const vec3 ambientColor = vec3(0.3);
    const vec3 nightAmbientColor = vec3(0.18);
    const vec3 rainColor = vec3(0.2);

    vec2 lightmap = texture(colortex1, texcoord).rg;

    float sunHeight = worldLightVector.y;
    float dayBrightness = smoothstep(-0.1, 0.1, sunHeight);

    vec3 shadow = vec3(0.0);
    vec3 skylight;
    vec3 ambient;

    bool isDaytime = (worldTime <= 12700 || worldTime >= 22900) && rainStrength == 0.0;

    if (isDaytime) {
        // skip the shadow sample loop entirely for surfaces facing away from the sun
        if (NdotL > 0.0) {
            shadow = getSoftShadow(shadowScreenPos, texcoord);
        }
        skylight = lightmap.g * skylightColor * mix(0.5, 1.0, dayBrightness);
        ambient = ambientColor * mix(0.3, 1.0, dayBrightness);
    } else {
        if (rainStrength > 0.1) {
            skylight = lightmap.g * rainColor;
        } else {
            skylight = lightmap.g * skylightColor * mix(0.7, 1.0, dayBrightness);
        }
        ambient = nightAmbientColor;
    }

    vec3 blocklight = lightmap.r * blocklightColor;
    vec3 sunlight = sunlightColor * NdotL * shadow * dayBrightness;

    vec3 lighting = blocklight + skylight + ambient + sunlight;
    color.rgb *= lighting;

    float material = texture(colortex3, texcoord).r;

    if (material > 0.5)
    {
        vec3 waterColor = vec3(0.01, 0.04, 0.08);
        color.rgb = mix(color.rgb, waterColor, 0.6);

    }
}
