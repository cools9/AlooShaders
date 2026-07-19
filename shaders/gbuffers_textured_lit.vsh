#version 330 compatibility

in vec2 mc_Entity;
out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
uniform mat4 gbufferModelViewInverse;
void main() {
  gl_Position = ftransform();
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  //lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);
  glcolor = gl_Color;
  normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
  normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space

  int blockId = int(mc_Entity.x);
  if (blockId == 100) {
      float wind =
          sin(position.x * 0.4 + frameTimeCounter * 2.0) +
          cos(position.z * 0.3 + frameTimeCounter * 1.8);

      wind *= 0.03;

      position.x += wind;
      position.z += wind * 0.5;
  }
}
