#ifndef AURELIA_SKY_H
#define AURELIA_SKY_H

#include <env.sh>

#define AURELIA_SKY_DAY_HORIZON vec3(0.72, 0.84, 0.96)
#define AURELIA_SKY_DAY_EDGE vec3(0.46, 0.66, 0.92)
#define AURELIA_SKY_DAY_ZENITH vec3(0.20, 0.42, 0.82)

#define AURELIA_SKY_DAWN_HORIZON vec3(1.00, 0.64, 0.46)
#define AURELIA_SKY_DAWN_EDGE vec3(0.80, 0.52, 0.64)
#define AURELIA_SKY_DAWN_ZENITH vec3(0.36, 0.46, 0.74)

#define AURELIA_SKY_DUSK_HORIZON vec3(1.00, 0.50, 0.30)
#define AURELIA_SKY_DUSK_EDGE vec3(0.72, 0.42, 0.58)
#define AURELIA_SKY_DUSK_ZENITH vec3(0.28, 0.30, 0.58)

#define AURELIA_SKY_NIGHT_HORIZON vec3(0.05, 0.07, 0.15)
#define AURELIA_SKY_NIGHT_EDGE vec3(0.03, 0.045, 0.11)
#define AURELIA_SKY_NIGHT_ZENITH vec3(0.01, 0.02, 0.07)

#define AURELIA_SKY_EDGE_POS 0.2
#define AURELIA_SKY_CURVE 0.5
#define AURELIA_SKY_HORIZON_BAND 0.12
#define AURELIA_SKY_SUNGLOW 0.35
#define AURELIA_SKY_RAIN_BLEND 0.8

vec3 aureliaSkyHorizon(vec3 engineFog, vec3 sunDir) {
  float day = smoothstep(0.05, 0.35, sunDir.y);
  float night = 1.0 - smoothstep(-0.2, 0.0, sunDir.y);
  float twi = 1.0 - day - night;
  float evening = smoothstep(-0.1, 0.1, sunDir.x);

  vec3 twiHorizon = mix(AURELIA_SKY_DAWN_HORIZON, AURELIA_SKY_DUSK_HORIZON, evening);
  vec3 horizon = AURELIA_SKY_DAY_HORIZON * day + twiHorizon * twi + AURELIA_SKY_NIGHT_HORIZON * night;

  return mix(horizon, engineFog, aureliaRain * AURELIA_SKY_RAIN_BLEND);
}

vec3 aureliaSkyColor(vec3 dir, vec3 engineFog, vec3 sunDir) {
  float day = smoothstep(0.05, 0.35, sunDir.y);
  float night = 1.0 - smoothstep(-0.2, 0.0, sunDir.y);
  float twi = 1.0 - day - night;
  float evening = smoothstep(-0.1, 0.1, sunDir.x);

  vec3 twiHorizon = mix(AURELIA_SKY_DAWN_HORIZON, AURELIA_SKY_DUSK_HORIZON, evening);
  vec3 twiEdge = mix(AURELIA_SKY_DAWN_EDGE, AURELIA_SKY_DUSK_EDGE, evening);
  vec3 twiZenith = mix(AURELIA_SKY_DAWN_ZENITH, AURELIA_SKY_DUSK_ZENITH, evening);

  vec3 horizon = aureliaSkyHorizon(engineFog, sunDir);
  vec3 edge = AURELIA_SKY_DAY_EDGE * day + twiEdge * twi + AURELIA_SKY_NIGHT_EDGE * night;
  vec3 zenith = AURELIA_SKY_DAY_ZENITH * day + twiZenith * twi + AURELIA_SKY_NIGHT_ZENITH * night;

  float rainBlend = aureliaRain * AURELIA_SKY_RAIN_BLEND;
  edge = mix(edge, engineFog * 0.9, rainBlend);
  zenith = mix(zenith, engineFog * 0.8, rainBlend);

  float up = clamp(dir.y, 0.0, 1.0);

  vec3 lower = mix(horizon, edge, smoothstep(0.0, AURELIA_SKY_EDGE_POS, up));
  vec3 sky = mix(lower, zenith, smoothstep(AURELIA_SKY_EDGE_POS * 0.5, 0.9, up));

  float glow = pow(max(dot(dir, sunDir), 0.0), 6.0) * twi * (1.0 - aureliaRain);
  sky += twiHorizon * glow * AURELIA_SKY_SUNGLOW;

  return sky;
}

#endif
