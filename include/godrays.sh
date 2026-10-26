#ifndef AURELIA_GODRAYS_H
#define AURELIA_GODRAYS_H

#include <noise.sh>
#include <env.sh>
#include <clouds.sh>

#define AURELIA_GODRAYS 1
#define AURELIA_GODRAY_DAWN 1.0
#define AURELIA_GODRAY_DUSK 0.7
#define AURELIA_GODRAY_DAY 0.3
#define AURELIA_GODRAY_INTENSITY 0.5
#define AURELIA_GODRAY_FALLOFF 3.0
#define AURELIA_GODRAY_STEPS 6
#define AURELIA_GODRAY_SKY_SIGN -1.0
#define AURELIA_UW_RAY_COLOR vec3(0.35, 0.75, 0.85)
#define AURELIA_UW_RAY_INTENSITY 0.5
#define AURELIA_UW_RAY_FREQ 5.0

float aureliaRayPattern(vec3 dir, vec3 axis, highp float time, float freq) {
  vec3 up = abs(axis.y) < 0.95 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
  vec3 t1 = normalize(cross(axis, up));
  vec3 t2 = cross(axis, t1);
  vec2 q = vec2(dot(dir, t1), dot(dir, t2));
  vec2 n = q / max(length(q), 0.0001);
  float r = aureliaNoise(n * freq + vec2(time * 0.04, 0.0)) * 0.6
          + aureliaNoise(n * freq * 2.3 + vec2(9.1, time * 0.07)) * 0.4;
  return smoothstep(0.35, 0.8, r);
}

float aureliaRayStrength(vec3 sunDir) {
  float day = smoothstep(0.05, 0.35, sunDir.y);
  float night = 1.0 - smoothstep(-0.2, 0.0, sunDir.y);
  float twi = 1.0 - day - night;
  float evening = smoothstep(-0.1, 0.1, sunDir.x);
  return mix(AURELIA_GODRAY_DAWN, AURELIA_GODRAY_DUSK, evening) * twi + AURELIA_GODRAY_DAY * day;
}

float aureliaRayOcclusion(vec3 dir, vec3 sunDir, highp vec2 camXZ, highp float time) {
  float cover = AURELIA_CLOUD_COVERAGE - aureliaRain * AURELIA_CLOUD_RAIN_GROW;
  float soft = AURELIA_CLOUD_SOFTNESS + aureliaRain * AURELIA_CLOUD_RAIN_SOFT;
  float vis = 0.0;

  for (int i = 0; i < AURELIA_GODRAY_STEPS; i++) {
    float t = (float(i) + 0.5) / float(AURELIA_GODRAY_STEPS);
    vec3 s = normalize(mix(dir, sunDir, t));
    highp vec2 world = camXZ + s.xz / max(s.y, 0.12) * AURELIA_CLOUD_ALTITUDE;
    highp vec2 p = (world + vec2(1.0, 0.4) * time * AURELIA_CLOUD_SPEED) * AURELIA_CLOUD_SCALE;
    highp float shape = aureliaNoise(p);
    vis += 1.0 - smoothstep(cover, cover + soft, shape);
  }

  return vis / float(AURELIA_GODRAY_STEPS);
}

vec3 aureliaGodrays(vec3 dir, vec3 sunDir, highp vec2 camXZ, highp float time) {
  float strength = aureliaRayStrength(sunDir) * (1.0 - aureliaRain);
  float cosT = dot(dir, sunDir);
  if (strength < 0.01 || cosT < 0.0 || sunDir.y < -0.05) {
    return vec3_splat(0.0);
  }

  float horizon = smoothstep(-0.02, 0.2, dir.y);
  float glow = pow(cosT, AURELIA_GODRAY_FALLOFF);
  float shafts = aureliaRayOcclusion(dir, sunDir, camXZ, time);
  shafts = shafts * shafts;
  float beam = pow(cosT, 1.5) * shafts;

  vec3 tint = mix(vec3(1.0, 0.58, 0.32), vec3(1.0, 0.9, 0.75), smoothstep(0.0, 0.3, sunDir.y));

  return tint * ((0.25 * glow + 0.75 * beam) * horizon * strength * AURELIA_GODRAY_INTENSITY);
}

vec3 aureliaUnderwaterRays(vec3 dir, vec3 sunDir, highp float time, float camDis) {
  float sunUp = smoothstep(0.0, 0.3, sunDir.y);
  if (sunUp < 0.01) {
    return vec3_splat(0.0);
  }

  vec3 axis = normalize(vec3(sunDir.x * 0.7, max(sunDir.y, 0.35), sunDir.z * 0.7));
  float pattern = aureliaRayPattern(dir, axis, time * 2.0, AURELIA_UW_RAY_FREQ);
  float spread = pow(max(dot(dir, axis), 0.0), 2.0);
  float path = 1.0 - exp(-camDis * 0.05);

  return AURELIA_UW_RAY_COLOR * (pattern * spread * path * sunUp * AURELIA_UW_RAY_INTENSITY);
}

#endif
