#version 330 compatibility

#define SATURATION 1.3 // [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
#include "/lib/distort.glsl"
#define SHADOW_RANGE 1
#define SHADOW_RADIUS 0.6

uniform sampler2D depthtex1;
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
uniform sampler2D colortex4; 
uniform sampler2D normals;
uniform sampler2D specular;
uniform float frameTimeCounter;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 adjustSaturation(vec3 color, float saturation) {
    float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
    return mix(vec3(luminance), color, saturation);
}

vec3 getMetalF0(int id) {
    if (id == 230) return vec3(0.531, 0.512, 0.496); // Iron
    if (id == 231) return vec3(0.944, 0.776, 0.373); // Gold
    if (id == 232) return vec3(0.912, 0.914, 0.920); // Aluminum
    if (id == 233) return vec3(0.556, 0.555, 0.555); // Chrome
    if (id == 234) return vec3(0.926, 0.721, 0.504); // Copper
    if (id == 235) return vec3(0.633, 0.626, 0.641); // Lead
    if (id == 236) return vec3(0.679, 0.642, 0.588); // Platinum
    if (id == 237) return vec3(0.962, 0.949, 0.922); // Silver
    return vec3(0.9); 
}

vec3 getF0(vec4 specularTex, vec3 albedo) {
    int id = int(specularTex.g * 255.0 + 0.5);
    if (id <= 229) {
        return vec3(specularTex.g); 
    } else if (id == 255) {
        return albedo;
    } else {
        return getMetalF0(id); 
    }
}

float getMetallic(vec4 specularTex) {
    int id = int(specularTex.g * 255.0 + 0.5);
    return id >= 230 ? 1.0 : 0.0; 
}

vec3 brdf(vec3 lightDir, vec3 viewDir, float roughness, vec3 normal, vec3 albedo, float metallic, vec3 reflectance) {

    float alpha = pow(roughness, 2.0);
    vec3 H = normalize(lightDir + viewDir);

    float NdotV = clamp(dot(normal, viewDir), 0.001, 1.0);
    float NdotL = clamp(dot(normal, lightDir), 0.001, 1.0);
    float NdotH = clamp(dot(normal, H), 0.001, 1.0);
    float VdotH = clamp(dot(viewDir, H), 0.001, 1.0);

    
    vec3 F0 = reflectance;
    vec3 fresnelReflectance = F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);

    
    vec3 rhoD = albedo / 3.141;
    rhoD *= (vec3(1.0) - fresnelReflectance);
    rhoD *= (1.0 - metallic); 

    
    float k = alpha / 2.0;
    float geometry = (NdotL / (NdotL * (1.0 - k) + k)) * (NdotV / (NdotV * (1.0 - k) + k));

    
    float lowerTerm = pow(NdotH, 2.0) * (pow(alpha, 2.0) - 1.0) + 1.0;
    float distribution = pow(alpha, 2.0) / (3.14159 * pow(lowerTerm, 2.0));

    vec3 cookTorrance = (fresnelReflectance * distribution * geometry) / (4.0 * NdotL * NdotV);

    vec3 BRDF = (rhoD + cookTorrance) * NdotL;

    return BRDF;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

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
    vec3 albedo = color.rgb; 

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
    const vec3 ambientColor = vec3(0.5);
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

    vec4 specularTex = texture(colortex4, texcoord); 
    float smoothness = specularTex.r;
    float roughness = pow(1.0 - smoothness, 2.0);
    vec3 F0 = getF0(specularTex, albedo);
    float metallic = getMetallic(specularTex);

    vec3 viewDir = normalize(-feetPlayerPos);
    vec3 lightDir = worldLightVector; 

    vec3 directLight = brdf(lightDir, viewDir, roughness, normal, albedo, metallic, F0)
                        * sunlightColor * shadow * dayBrightness; 

    vec3 blocklight = lightmap.r * blocklightColor;
    vec3 indirect = albedo * (blocklight + skylight + ambient);
    float ambientNdotV = clamp(dot(normal, viewDir), 0.001, 1.0);
    vec3 ambientFresnel = fresnelSchlick(ambientNdotV, F0);
    vec3 ambientSpecular = ambientFresnel * (skylight + ambient) * (1.0 - roughness);
    vec3 specularSum = directLight + ambientSpecular;
    specularSum = specularSum / (1.0 + specularSum); // local Reinhard, specular-only

    color.rgb = indirect + specularSum;

    
    float material = texture(colortex3, texcoord).r;

    if (material > 0.5)
    {
        vec2 rippleTexcoord = texcoord;
        float t = frameTimeCounter;
        rippleTexcoord.x += sin(texcoord.y * 80.0 + t * 2.0) * 0.005;
        rippleTexcoord.y += cos(texcoord.x * 80.0 + t * 1.7) * 0.003;

    
        float trueOpaqueDepth = texture(depthtex1, texcoord).r;
        vec3 trueOpaqueNDC = vec3(texcoord.xy, trueOpaqueDepth) * 2.0 - 1.0;
        vec3 trueOpaqueViewPos = projectAndDivide(gbufferProjectionInverse, trueOpaqueNDC);
        float trueWaterDepth = distance(viewPos, trueOpaqueViewPos);

    
        float rippleOpaqueDepth = texture(depthtex1, rippleTexcoord).r;
        vec3 rippleOpaqueNDC = vec3(rippleTexcoord.xy, rippleOpaqueDepth) * 2.0 - 1.0;
        vec3 rippleOpaqueViewPos = projectAndDivide(gbufferProjectionInverse, rippleOpaqueNDC);
        float rippleWaterDepth = distance(viewPos, rippleOpaqueViewPos);

    
        float waterDepth = abs(rippleWaterDepth - trueWaterDepth) > 2.0 ? trueWaterDepth : rippleWaterDepth;

        vec3 shallowColor = vec3(0.10, 0.35, 0.45);
        vec3 deepColor = vec3(0.01, 0.04, 0.08);

        float depthFactor = 1.0 - exp(-waterDepth * 0.05);
        depthFactor = smoothstep(0.0, 1.0, depthFactor);
        vec3 waterColor = mix(shallowColor, deepColor, depthFactor);

        float blendAmount = mix(0.25, 0.85, depthFactor);
        color.rgb = mix(color.rgb, waterColor, blendAmount);

    
        vec3 reflectionNormal = normalize(mix(vec3(0.0, 1.0, 0.0), normal, 0.3));

        vec3 waterF0 = vec3(0.02);
        float NdotV = clamp(dot(reflectionNormal, viewDir), 0.001, 1.0);
        float nightFactor = isDaytime ? dayBrightness : 0.0; 

        vec3 fresnel = fresnelSchlick(NdotV, waterF0);
        float reflectionStrength = fresnel.r * 0.5;
        reflectionStrength *= smoothstep(0.3, 0.05, NdotV);

        vec3 skyColor = mix(vec3(0.4, 0.55, 0.75), vec3(0.9, 0.95, 1.0), nightFactor);
        vec3 reflection = skyColor * nightFactor;

        color.rgb = mix(color.rgb, reflection, reflectionStrength * (nightFactor > 0.0 ? 1.0 : 0.15));
    }
    color.rgb = adjustSaturation(color.rgb, SATURATION);
}
