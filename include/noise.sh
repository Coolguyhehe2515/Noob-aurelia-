#ifndef AURELIA_NOISE_H
#define AURELIA_NOISE_H

#include <config.sh>

highp float aureliaHash(highp vec2 p) {
  highp vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

highp float aureliaNoise(highp vec2 p) {
  highp vec2 i = floor(p);
  highp vec2 f = fract(p);
  highp vec2 u = f * f * (3.0 - 2.0 * f);
  highp float a = aureliaHash(i);
  highp float b = aureliaHash(i + vec2(1.0, 0.0));
  highp float c = aureliaHash(i + vec2(0.0, 1.0));
  highp float d = aureliaHash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

#endif
