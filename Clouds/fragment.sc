$input v_color0

#include <bgfx_shader.sh>
#include <main.sh>

#define AURELIA_CLOUD_TEXTURE 1

#if AURELIA_CLOUD_TEXTURE
  SAMPLER2D_AUTOREG(s_CloudNoise);
#endif

uniform vec4 TimeOfDay;
uniform vec4 CameraPosition;
uniform vec4 FogColor;
uniform vec4 ViewPositionAndTime;
uniform vec4 FogAndDistanceControl;

void main() {
  aureliaRain = aureliaRainFactor(FogAndDistanceControl.xyz);

  vec3 dir = normalize(v_color0.xyz);
  vec3 sunDir = aureliaSunDir(TimeOfDay.x);
  vec3 horizonCol = aureliaSkyHorizon(vec3(0.45, 0.5, 0.56), sunDir);

  #if AURELIA_CLOUD_TEXTURE
    vec4 c = aureliaCloudsRawTex(s_CloudNoise, dir, CameraPosition.xz, ViewPositionAndTime.w, sunDir, horizonCol, 1.0);
  #else
    vec4 c = aureliaCloudsRaw(dir, CameraPosition.xz, ViewPositionAndTime.w, sunDir, horizonCol, 1.0);
  #endif

  #if AURELIA_GODRAYS
    c.rgb += aureliaGodrays(dir, sunDir, CameraPosition.xz, ViewPositionAndTime.w);
  #endif

  gl_FragColor = vec4(aureliaColorGrade(c.rgb), c.a);
}
