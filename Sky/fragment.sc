#ifndef INSTANCING
  $input v_worldPos
#endif

#include <bgfx_shader.sh>
#include <main.sh>

#ifndef INSTANCING
  uniform vec4 FogColor;
#endif

void main() {
  #ifndef INSTANCING
    vec3 dir = normalize(v_worldPos);
    gl_FragColor = vec4(aureliaColorGrade(aureliaSkyColor(dir, FogColor.rgb)), 1.0);
  #else
    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  #endif
}
