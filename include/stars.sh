#ifndef AURELIA_STARS_H
#define AURELIA_STARS_H

#define AURELIA_STAR_BRIGHTNESS 1.0
#define AURELIA_STAR_TWINKLE 0.5
#define AURELIA_STAR_SPEED 2.0

float aureliaStarTwinkle(vec3 pos, highp float time) {
  float p = dot(pos, vec3(0.9, 1.2, 0.6));
  float a = sin(time * AURELIA_STAR_SPEED + p);
  float b = sin(time * AURELIA_STAR_SPEED * 1.7 + p * 2.3);
  return max(1.0 + AURELIA_STAR_TWINKLE * 0.5 * (a + b), 0.0);
}

#endif
