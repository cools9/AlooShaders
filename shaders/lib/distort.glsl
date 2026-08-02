const int shadowMapResolution = 2048;
//const float shadowDistanceRenderMul = 1.0;

const bool colortex2Nearest = true;
const bool colortex3Nearest = true;
const bool colortex4Nearest = true;
const bool shadowtex0Nearest = false;
const bool shadowtex1Nearest = false;
const bool shadowcolor0Nearest = false;
#define SHADOW_RADIUS 1
#define SHADOW_RANGE 1

vec3 distortShadowClipPos(vec3 shadowClipPos){
  float distortionFactor = length(shadowClipPos.xy); 
  distortionFactor += 0.1; 

  shadowClipPos.xy /= distortionFactor;
  shadowClipPos.z *= 0.5; 
  return shadowClipPos;
}
