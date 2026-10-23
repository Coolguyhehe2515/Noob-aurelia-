#ifndef INSTANCING
  $input v_worldPos
#endif

#include <bgfx_shader.sh>
#include <main.sh>

#ifndef INSTANCING
  uniform vec4 TimeOfDay;
  uniform vec4 FogColor;
  uniform vec4 FogAndDistanceControl;
#endif

void main() {
  #ifndef INSTANCING
    aureliaRain = aureliaRainFactor(FogAndDistanceControl.xyz);

    vec3 dir = normalize(v_worldPos);
    vec3 sunDir = aureliaSunDir(TimeOfDay.x);

    vec3 sky = aureliaSkyColor(dir, FogColor.rgb, sunDir);
    if (aureliaUnderwater(FogColor.rgb, FogAndDistanceControl.xyz)) {
      sky = FogColor.rgb;
    }

    gl_FragColor = vec4(aureliaColorGrade(sky), 1.0);
  #else
    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  #endif
}
