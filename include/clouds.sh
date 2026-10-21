#ifndef AURELIA_CLOUDS_H
#define AURELIA_CLOUDS_H

#include <noise.sh>
#include <tonemap.sh>

#define AURELIA_CLOUD_OCTAVES 4
#define AURELIA_CLOUD_ALTITUDE 140.0
#define AURELIA_CLOUD_SCALE 0.008
#define AURELIA_CLOUD_SPEED 6.0
#define AURELIA_CLOUD_COVERAGE 0.46
#define AURELIA_CLOUD_SOFTNESS 0.25
#define AURELIA_CLOUD_OPACITY 0.95
#define AURELIA_CLOUD_SHADOW 2.2
#define AURELIA_CLOUD_SILVER 1.4
#define AURELIA_CLOUD_SHADE 0.55

vec3 aureliaSunDir(float timeOfDay) {
  float a = 6.2831853 * timeOfDay;
  return vec3(sin(a), cos(a), 0.0);
}

highp float aureliaCloudFbm(highp vec2 p) {
  highp float sum = 0.0;
  highp float amp = 0.5;
  for (int i = 0; i < AURELIA_CLOUD_OCTAVES; i++) {
    sum += amp * aureliaNoise(p);
    p = p * 2.03 + vec2(17.1, 9.2);
    amp *= 0.5;
  }
  return sum;
}

float aureliaCloudDensity(highp vec2 p, highp float time) {
  highp float shape = aureliaCloudFbm(p) + 0.4 * (aureliaNoise(p * 0.18 + vec2(time * 0.003, time * 0.002)) - 0.5);
  return smoothstep(AURELIA_CLOUD_COVERAGE, AURELIA_CLOUD_COVERAGE + AURELIA_CLOUD_SOFTNESS, shape);
}

float aureliaCloudShadow(highp vec3 worldPos, highp vec2 camXZ, highp float time, vec3 sunDir, float skyLight) {
  float sunUp = smoothstep(0.0, 0.25, sunDir.y);
  float heightFade = 1.0 - smoothstep(AURELIA_CLOUD_ALTITUDE - 40.0, AURELIA_CLOUD_ALTITUDE, worldPos.y);
  float strength = sunUp * skyLight * heightFade;
  if (strength <= 0.0) {
    return 1.0;
  }

  highp vec2 world = camXZ + worldPos.xz + sunDir.xz / max(sunDir.y, 0.15) * max(AURELIA_CLOUD_ALTITUDE - worldPos.y, 0.0);
  highp vec2 p = (world + vec2(1.0, 0.4) * time * AURELIA_CLOUD_SPEED) * AURELIA_CLOUD_SCALE;

  return 1.0 - AURELIA_CLOUD_SHADE * aureliaCloudDensity(p, time) * strength;
}

vec4 aureliaCloudsRaw(vec3 dir, highp vec2 camXZ, highp float time, vec3 sunDir, vec3 fogColor, float shadeTap) {
  float up = dir.y;
  if (up < 0.01) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  highp vec2 world = camXZ + dir.xz / max(up, 0.04) * AURELIA_CLOUD_ALTITUDE;
  highp vec2 p = (world + vec2(1.0, 0.4) * time * AURELIA_CLOUD_SPEED) * AURELIA_CLOUD_SCALE;

  float d = aureliaCloudDensity(p, time);
  if (d < 0.003) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  vec3 lightDir = sunDir.y >= 0.0 ? sunDir : -sunDir;
  vec2 toLight = lightDir.xz / max(lightDir.y, 0.2);
  float dl = shadeTap > 0.5 ? aureliaCloudDensity(p + toLight * 0.06, time) : d;

  float opticalDepth = dl * AURELIA_CLOUD_SHADOW + d * 0.8;
  float direct = exp(-opticalDepth);

  float cosT = dot(dir, lightDir);
  float silver = pow(max(cosT, 0.0), 10.0) * (1.0 - d) * AURELIA_CLOUD_SILVER;

  float sunUp = smoothstep(-0.08, 0.12, sunDir.y);
  vec3 sunCol = mix(vec3(1.0, 0.5, 0.2), vec3(1.0, 0.96, 0.88), smoothstep(0.0, 0.45, sunDir.y));
  vec3 moonCol = vec3(0.45, 0.55, 0.85) * 0.18;
  vec3 lightCol = mix(moonCol, sunCol, sunUp);

  vec3 ambient = fogColor * 0.75 + lightCol * 0.2;
  vec3 col = ambient * (1.0 - 0.35 * d) + lightCol * (direct * 1.1 + silver);

  float horizon = smoothstep(0.0, 0.35, up);
  col = mix(fogColor, col, 0.4 + 0.6 * horizon);

  float alpha = d * AURELIA_CLOUD_OPACITY * smoothstep(0.01, 0.14, up);
  return vec4(col, alpha);
}

vec4 aureliaClouds(vec3 dir, highp vec2 camXZ, highp float time, vec3 sunDir, vec3 fogColor) {
  vec4 c = aureliaCloudsRaw(dir, camXZ, time, sunDir, fogColor, 1.0);
  return vec4(aureliaColorGrade(c.rgb), c.a);
}

#endif
