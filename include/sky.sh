#ifndef AURELIA_SKY_H
#define AURELIA_SKY_H

#define AURELIA_ZENITH_DEPTH 0.7

vec3 aureliaSkyColor(vec3 dir, vec3 fogColor) {
  float t = sqrt(clamp(dir.y, 0.0, 1.0));
  vec3 zenith = mix(fogColor, fogColor * fogColor, AURELIA_ZENITH_DEPTH);
  return mix(fogColor, zenith, t);
}

#endif
