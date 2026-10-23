#ifndef AURELIA_CAUSTICS_H
#define AURELIA_CAUSTICS_H

#include <noise.sh>

#define AURELIA_CAUSTICS 1
#define AURELIA_CAUSTIC_STRENGTH 0.9
#define AURELIA_CAUSTIC_SCALE 0.8
#define AURELIA_CAUSTIC_SPEED 0.5
#define AURELIA_CAUSTIC_SHARP 9.0
#define AURELIA_CAUSTIC_DEPTH 28.0
#define AURELIA_SEA_LEVEL 62.0

float aureliaCaustics(highp vec2 p, highp float time) {
  highp vec2 q = p * AURELIA_CAUSTIC_SCALE;
  highp float t = time * AURELIA_CAUSTIC_SPEED;
  float a = 1.0 - abs(aureliaNoise(q + vec2(t, t * 0.6)) * 2.0 - 1.0);
  float b = 1.0 - abs(aureliaNoise(q * 1.37 + vec2(-t * 0.8, t) + 7.7) * 2.0 - 1.0);
  return clamp(pow(a, AURELIA_CAUSTIC_SHARP) + pow(b, AURELIA_CAUSTIC_SHARP), 0.0, 1.0);
}

#endif
