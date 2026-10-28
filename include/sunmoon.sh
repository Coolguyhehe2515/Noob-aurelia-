#ifndef AURELIA_SUNMOON_H
#define AURELIA_SUNMOON_H

#include <tonemap.sh>
#include <config.sh>


vec4 aureliaSunDisc(vec2 uv, float sunY) {
  float d = length(uv - 0.5) * 2.0;

  float coreR = AURELIA_SUN_DISC / AURELIA_SUN_SIZE;
  float c = d / coreR;
  float core = exp(-c * c * 2.0);

  float glow = exp(-d * d * AURELIA_SUN_FALLOFF) * (1.0 - smoothstep(0.7, 1.0, d)) * AURELIA_SUN_GLOW;

  float m = clamp(core + glow, 0.0, 1.0);

  vec3 tint = mix(vec3(1.0, 0.55, 0.25), vec3(1.0, 0.96, 0.86), smoothstep(0.0, 0.35, sunY));
  vec3 col = aureliaColorGrade(tint * (1.0 + core * 2.5));

  return vec4(col, m);
}

#endif
