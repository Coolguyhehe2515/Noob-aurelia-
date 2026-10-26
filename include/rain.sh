#ifndef AURELIA_RAIN_H
#define AURELIA_RAIN_H

#include <clouds.sh>

#define AURELIA_RAIN_WIDTH 0.5
#define AURELIA_RAIN_LENGTH 1.25
#define AURELIA_RAIN_OPACITY 0.65
#define AURELIA_RAIN_EDGE_LOW 0.1
#define AURELIA_RAIN_EDGE_HIGH 0.6

#define AURELIA_WIND_BASE 0.12
#define AURELIA_WIND_GUST 0.35
#define AURELIA_WIND_TURN 1.2
#define AURELIA_WIND_SIGN 1.0

float aureliaRainMask(highp vec2 absXZ, highp float time) {
  highp vec2 p = (absXZ + vec2(1.0, 0.4) * time * AURELIA_CLOUD_SPEED) * AURELIA_CLOUD_SCALE;
  return smoothstep(AURELIA_RAIN_EDGE_LOW, AURELIA_RAIN_EDGE_HIGH, aureliaCloudDensityCoarse(p, time));
}

vec2 aureliaRainWind(highp vec2 absXZ, highp float time) {
  highp vec2 q = absXZ * 0.03;
  float turn = aureliaNoise(vec2(time * 0.06, 0.0) + q) - 0.5;
  float angle = 0.38 + turn * 2.0 * AURELIA_WIND_TURN;
  float gust = smoothstep(0.5, 0.85, aureliaNoise(vec2(time * 0.35 + 31.7, 7.3) + q));
  float strength = AURELIA_WIND_BASE + AURELIA_WIND_GUST * gust;
  return vec2(cos(angle), sin(angle)) * strength;
}

#endif
