#ifndef INSTANCING
  $input v_worldPos
#endif

#include <bgfx_shader.sh>
#include <tonemap.sh>

#ifndef INSTANCING
  uniform vec4 FogColor;
#endif

#define AURELIA_ZENITH_DEPTH 0.7

void main() {
  #ifndef INSTANCING
    vec3 dir = normalize(v_worldPos);
    float t = sqrt(clamp(dir.y, 0.0, 1.0));

    vec3 horizon = FogColor.rgb;
    vec3 zenith = mix(horizon, horizon * horizon, AURELIA_ZENITH_DEPTH);

    vec3 sky = mix(horizon, zenith, t);

    gl_FragColor = vec4(aureliaColorGrade(sky), 1.0);
  #else
    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  #endif
}
