#ifndef AURELIA_CLOUDS_H
#define AURELIA_CLOUDS_H

#include <noise.sh>
#include <tonemap.sh>
#include <env.sh>

#define AURELIA_CLOUD_ALTITUDE 140.0
#define AURELIA_CLOUD_SCALE 0.008
#define AURELIA_CLOUD_SPEED 6.0
#define AURELIA_CLOUD_COVERAGE 0.42
#define AURELIA_CLOUD_SOFTNESS 0.22
#define AURELIA_CLOUD_DETAIL 0.1
#define AURELIA_CLOUD_OPACITY 0.95
#define AURELIA_CLOUD_SHADOW 2.2
#define AURELIA_CLOUD_SILVER 1.2
#define AURELIA_CLOUD_SHADE 0.55
#define AURELIA_CLOUD_RAIN_GROW 0.32
#define AURELIA_CLOUD_RAIN_SOFT 0.2
#define AURELIA_CLOUD_RAIN_DARK 0.65

vec3 aureliaSunDir(float timeOfDay) {
  float a = 6.2831853 * timeOfDay;
  return vec3(sin(a), cos(a), 0.0);
}

highp float aureliaNoiseTile(highp vec2 p, highp float period) {
  highp vec2 i = floor(p);
  highp vec2 f = fract(p);
  highp vec2 u = f * f * (3.0 - 2.0 * f);
  highp float a = aureliaHash(mod(i, period));
  highp float b = aureliaHash(mod(i + vec2(1.0, 0.0), period));
  highp float c = aureliaHash(mod(i + vec2(0.0, 1.0), period));
  highp float d = aureliaHash(mod(i + vec2(1.0, 1.0), period));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

highp float aureliaCloudWeather(highp vec2 p, highp float time) {
  return aureliaNoiseTile(p * 0.2 + vec2(time * 0.003, time * 0.002), 16.0);
}

highp float aureliaCloudBase(highp vec2 p, highp float w) {
  return 0.65 * aureliaNoiseTile(p, 16.0) + 0.35 * aureliaNoiseTile(p * 2.0 + vec2(17.0, 9.0), 32.0) + 0.55 * (w - 0.5);
}

float aureliaCloudCover(highp float shape) {
  float cover = AURELIA_CLOUD_COVERAGE - aureliaRain * AURELIA_CLOUD_RAIN_GROW;
  float soft = AURELIA_CLOUD_SOFTNESS + aureliaRain * AURELIA_CLOUD_RAIN_SOFT;
  return smoothstep(cover, cover + soft, shape);
}

float aureliaCloudDensityCoarse(highp vec2 p, highp float time) {
  return aureliaCloudCover(aureliaCloudBase(p, aureliaCloudWeather(p, time)));
}

float aureliaCloudDensity(highp vec2 p, highp float time) {
  highp float w = aureliaCloudWeather(p, time);
  highp float shape = aureliaCloudBase(p, w) + AURELIA_CLOUD_DETAIL * (aureliaNoiseTile(p * 4.0 + vec2(3.0, 5.0), 64.0) - 0.5);
  return aureliaCloudCover(shape);
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

  float shade = mix(AURELIA_CLOUD_SHADE, 0.7, aureliaRain);
  return 1.0 - shade * aureliaCloudDensityCoarse(p, time) * strength;
}

vec4 aureliaCloudShade(vec3 dir, float d, float dl, vec3 sunDir, vec3 fogColor) {
  float up = dir.y;
  vec3 lightDir = sunDir.y >= 0.0 ? sunDir : -sunDir;

  float direct = exp(-(dl * AURELIA_CLOUD_SHADOW + d * 0.5));

  float cosT = dot(dir, lightDir);
  float silver = pow(max(cosT, 0.0), 10.0) * (1.0 - d) * AURELIA_CLOUD_SILVER * (1.0 - aureliaRain);

  float dayF = smoothstep(-0.06, 0.28, sunDir.y);
  float twi = dayF * (1.0 - smoothstep(0.1, 0.45, sunDir.y));

  vec3 sunCol = mix(vec3(1.0, 0.5, 0.2), vec3(1.0, 0.97, 0.9), smoothstep(0.0, 0.45, sunDir.y));
  vec3 moonCol = vec3(0.30, 0.36, 0.55) * 0.22;
  vec3 lightCol = mix(moonCol, sunCol, dayF);
  lightCol *= 1.0 - AURELIA_CLOUD_RAIN_DARK * aureliaRain;

  vec3 ambient = mix(vec3(0.045, 0.055, 0.095), vec3(0.50, 0.58, 0.72), dayF);
  ambient = mix(ambient, vec3(0.56, 0.44, 0.46), twi * 0.5);
  ambient *= 1.0 - 0.4 * aureliaRain;

  vec3 col = ambient * (1.0 - 0.3 * d) + lightCol * (direct * 0.85 + silver);

  float gray = dot(col, vec3(0.3333, 0.3333, 0.3333));
  col = mix(col, vec3_splat(gray * 0.85), aureliaRain * 0.5);

  float horizon = smoothstep(0.0, 0.35, up);
  col = mix(fogColor, col, 0.4 + 0.6 * horizon);

  float alpha = d * mix(AURELIA_CLOUD_OPACITY, 1.0, aureliaRain) * smoothstep(0.01, 0.14, up);
  return vec4(col, alpha);
}

vec4 aureliaCloudsRaw(vec3 dir, highp vec2 camXZ, highp float time, vec3 sunDir, vec3 fogColor, float shadeTap) {
  float up = dir.y;
  if (up < 0.01) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  highp vec2 world = camXZ + dir.xz / max(up, 0.04) * AURELIA_CLOUD_ALTITUDE;
  highp vec2 p = (world + vec2(1.0, 0.4) * time * AURELIA_CLOUD_SPEED) * AURELIA_CLOUD_SCALE;

  highp float w = aureliaCloudWeather(p, time);
  highp float baseShape = aureliaCloudBase(p, w);
  float d = aureliaCloudCover(baseShape + AURELIA_CLOUD_DETAIL * (aureliaNoiseTile(p * 4.0 + vec2(3.0, 5.0), 64.0) - 0.5));
  if (d < 0.003) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  vec3 lightDir = sunDir.y >= 0.0 ? sunDir : -sunDir;
  float dl = d;
  if (shadeTap > 0.5) {
    vec2 toLight = lightDir.xz / max(lightDir.y, 0.2);
    dl = aureliaCloudCover(aureliaCloudBase(p + toLight * 0.06, w));
  }

  return aureliaCloudShade(dir, d, dl, sunDir, fogColor);
}

vec4 aureliaCloudsRawTex(sampler2D tex, vec3 dir, highp vec2 camXZ, highp float time, vec3 sunDir, vec3 fogColor, float shadeTap) {
  float up = dir.y;
  if (up < 0.01) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  highp vec2 world = camXZ + dir.xz / max(up, 0.04) * AURELIA_CLOUD_ALTITUDE;
  highp vec2 p = (world + vec2(1.0, 0.4) * time * AURELIA_CLOUD_SPEED) * AURELIA_CLOUD_SCALE;

  vec3 t0 = texture2D(tex, fract(p * 0.0625)).rgb;
  float w = texture2D(tex, fract((p * 0.2 + vec2(time * 0.003, time * 0.002)) * 0.0625)).r;
  float d = aureliaCloudCover(0.65 * t0.r + 0.35 * t0.g + 0.55 * (w - 0.5) + AURELIA_CLOUD_DETAIL * (t0.b - 0.5));
  if (d < 0.003) {
    return vec4(0.0, 0.0, 0.0, 0.0);
  }

  vec3 lightDir = sunDir.y >= 0.0 ? sunDir : -sunDir;
  float dl = d;
  if (shadeTap > 0.5) {
    vec2 toLight = lightDir.xz / max(lightDir.y, 0.2);
    vec2 tl = texture2D(tex, fract((p + toLight * 0.06) * 0.0625)).rg;
    dl = aureliaCloudCover(0.65 * tl.r + 0.35 * tl.g + 0.55 * (w - 0.5));
  }

  return aureliaCloudShade(dir, d, dl, sunDir, fogColor);
}

vec4 aureliaClouds(vec3 dir, highp vec2 camXZ, highp float time, vec3 sunDir, vec3 fogColor) {
  vec4 c = aureliaCloudsRaw(dir, camXZ, time, sunDir, fogColor, 1.0);
  return vec4(aureliaColorGrade(c.rgb), c.a);
}

#endif
