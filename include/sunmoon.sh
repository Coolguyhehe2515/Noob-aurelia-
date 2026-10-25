#ifndef AURELIA_SUNMOON_H
#define AURELIA_SUNMOON_H

#include <tonemap.sh>

#define AURELIA_SUN_SIZE 1.0
#define AURELIA_MOON_SIZE 1.0
#define AURELIA_SUN_DISC 0.1
#define AURELIA_SUN_BLOOM 1.0
#define AURELIA_SUN_HALO 0.12
#define AURELIA_MOON_BRIGHTNESS 1.0

vec4 aureliaSunDisc(vec2 uv, float sunY) {
  float d = length(uv - 0.5) * 2.0;

  float core = 1.0 - smoothstep(AURELIA_SUN_DISC * 0.8, AURELIA_SUN_DISC, d);
  float bloom = pow(max(1.0 - d, 0.0), 2.5) * AURELIA_SUN_BLOOM;
  float ring = (d - 0.55) / 0.08;
  float halo = exp(-ring * ring) * AURELIA_SUN_HALO;

  float m = clamp(core + bloom + halo, 0.0, 1.0);

  vec3 tint = mix(vec3(1.0, 0.55, 0.25), vec3(1.0, 0.95, 0.85), smoothstep(0.0, 0.35, sunY));
  vec3 col = aureliaColorGrade(tint * (1.0 + core * 2.0));

  return vec4(col, m);
}

#endif
