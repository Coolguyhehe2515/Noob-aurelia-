#ifndef INSTANCING
  $input v_worldPos
#endif

#include <bgfx_shader.sh>
#include <main.sh>

#ifndef INSTANCING
  uniform vec4 TimeOfDay;
  uniform vec4 FogColor;
  uniform vec4 FogAndDistanceControl;
  uniform vec4 ViewPositionAndTime;
  uniform vec4 CameraPosition;
#endif

void main() {
  #ifndef INSTANCING
    aureliaRain = aureliaRainFactor(FogAndDistanceControl.xyz);

    vec3 dir = normalize(v_worldPos);
    vec3 sunDir = aureliaSunDir(TimeOfDay.x);

    vec3 sky = aureliaSkyColor(dir, FogColor.rgb, sunDir);

    if (aureliaUnderwater(FogColor.rgb, FogAndDistanceControl.xyz)) {
      sky = FogColor.rgb;

      #ifdef AURELIA_GODRAYS
        sky += aureliaUnderwaterRays(dir, sunDir, ViewPositionAndTime.w, 80.0);
      #endif
    } else {
      #ifdef AURELIA_GODRAYS
        sky += aureliaGodrays(dir * AURELIA_GODRAY_SKY_SIGN, sunDir, CameraPosition.xz, ViewPositionAndTime.w);
      #endif
    }

    gl_FragColor = vec4(aureliaColorGrade(sky), 1.0);
  #else
    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  #endif
}
