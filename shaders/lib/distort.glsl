const int shadowMapResolution = 2048;
//const float shadowDistanceRenderMul = 1.0;


const bool shadowtex0Nearest = false;
const bool shadowtex1Nearest = false;
const bool shadowcolor0Nearest = false;
#define SHADOW_RADIUS 1
#define SHADOW_RANGE 1

vec3 distortShadowClipPos(vec3 shadowClipPos){
  float distortionFactor = length(shadowClipPos.xy); // distance from the player in shadow clip space
  distortionFactor += 0.1; // very small distances can cause issues so we add this to slightly reduce the distortion

  shadowClipPos.xy /= distortionFactor;
  shadowClipPos.z *= 0.5; // increases shadow distance on the Z axis, which helps when the sun is very low in the sky
  return shadowClipPos;
}
