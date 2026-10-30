#ifndef AURELIA_ENDSKY_H
#define AURELIA_ENDSKY_H

#include <tonemap.sh>
#include <config.sh>

vec3 aureliaEndSky(sampler2D tex, vec3 dir) {
  highp float yaw = atan2(dir.z, dir.x) * 0.15915494 + 0.5 + AURELIA_END_YAW;
  highp float pitch = acos(clamp(dir.y, -1.0, 1.0)) * 0.31830989;

  #ifdef AURELIA_END_FLIP_V
    pitch = 1.0 - pitch;
  #endif

  vec3 col = texture2DLod(tex, vec2(yaw, pitch), 0.0).rgb;
  col *= AURELIA_END_BRIGHTNESS;

  #ifdef AURELIA_END_GRADE
    col = aureliaColorGrade(col);
  #endif

  return col;
}

#endif
