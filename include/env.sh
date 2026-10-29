#ifndef AURELIA_ENV_H
#define AURELIA_ENV_H

#include <config.sh>

float aureliaRain = 0.0;

float aureliaRainFactor(vec3 fogControl) {
  vec2 clearFog = vec2(0.5 + 20.0 / fogControl.z, 1.0);
  vec2 rainFog = vec2(0.23, 0.70);
  vec2 f = clamp((fogControl.xy - clearFog) / (rainFog - clearFog), vec2(0.0, 0.0), vec2(1.0, 1.0));
  float v = f.x * f.y;
  return v * v * (3.0 - 2.0 * v);
}

bool aureliaUnderwater(vec3 fogColor, vec3 fogControl) {
  return fogControl.x == 0.0 && fogControl.y < 0.8 && (fogColor.b > fogColor.r || fogColor.g > fogColor.r);
}

vec3 aureliaUnderwaterFog(vec3 fogColor) {
  return mix(fogColor, AURELIA_UW_FOG_COLOR, AURELIA_UW_FOG_TINT);
}

#endif
