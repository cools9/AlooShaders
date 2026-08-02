#version 330 compatibility
uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform vec3 fogColor;
uniform float far;
uniform int isEyeInWater;
in vec2 texcoord;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  float depth = texture(depthtex0, texcoord).r;
  if(depth == 1.0){
    return;
  }
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);

  vec3 currentFogColor = fogColor;
  float density = 0.01; // normal above-water fog density

  if (isEyeInWater == 1) {
      currentFogColor = vec3(0.12, 0.15, 0.35); // deep blue underwater tint
      density = 0.12; // much thicker falloff — things vanish into fog quickly underwater
  }

  float fogFactor = 1.0 - exp(-length(viewPos) * density);
  color.rgb = mix(color.rgb, currentFogColor, clamp(fogFactor, 0.0, 1.0));
}