$input v_color0

#include <bgfx_shader.sh>
#include <main.sh>

uniform vec4 TimeOfDay;
uniform vec4 CameraPosition;
uniform vec4 FogColor;
uniform vec4 ViewPositionAndTime;
uniform vec4 FogAndDistanceControl;

void main() {
  aureliaRain = aureliaRainFactor(FogAndDistanceControl.xyz);

  vec3 dir = normalize(v_color0.xyz);
  vec3 sunDir = aureliaSunDir(TimeOfDay.x);

  vec4 c = aureliaCloudsRaw(dir, CameraPosition.xz, ViewPositionAndTime.w, sunDir, aureliaSkyHorizon(vec3(0.45, 0.5, 0.56), sunDir), 1.0);

  #if AURELIA_GODRAYS
    c.rgb += aureliaGodrays(dir, sunDir, CameraPosition.xz, ViewPositionAndTime.w);
  #endif

  gl_FragColor = vec4(aureliaColorGrade(c.rgb), c.a);
}
