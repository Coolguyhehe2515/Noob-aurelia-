#ifndef AURELIA_SKY_H
#define AURELIA_SKY_H

#include <env.sh>
#include <config.sh>


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
