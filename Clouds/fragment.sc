$input v_color0

#include <bgfx_shader.sh>
#include <main.sh>

uniform vec4 TimeOfDay;
uniform vec4 CameraPosition;
uniform vec4 FogColor;
uniform vec4 ViewPositionAndTime;

void main() {
  vec3 dir = normalize(v_color0.xyz);
  vec3 sunDir = aureliaSunDir(TimeOfDay.x);

  gl_FragColor = aureliaClouds(dir, CameraPosition.xz, ViewPositionAndTime.w, sunDir, FogColor.rgb);
}
