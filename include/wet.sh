#ifndef AURELIA_WET_H
#define AURELIA_WET_H

#include <noise.sh>
#include <sky.sh>
#include <clouds.sh>

#define AURELIA_WET_DARKEN 0.3
#define AURELIA_WET_SPEC 0.5
#define AURELIA_PUDDLE_SCALE 0.22
#define AURELIA_PUDDLE_EDGE 0.66
#define AURELIA_PUDDLE_GROW 0.14
#define AURELIA_PUDDLE_DARKEN 0.45
#define AURELIA_PUDDLE_REFLECT 1.6
#define AURELIA_RIPPLE_DENSITY 2.0
#define AURELIA_RIPPLE_SPEED 0.9
#define AURELIA_RIPPLE_AMP 0.35
#define AURELIA_SPLASH_DENSITY 3.0
#define AURELIA_SPLASH_SPEED 1.6
#define AURELIA_SPLASH_STRENGTH 0.8
#define AURELIA_SPLASH_AMOUNT 0.5

float aureliaWetness(float rain) {
  return smoothstep(0.1, 0.8, rain);
}

float aureliaPuddleMask(highp vec2 absXZ, float wet) {
  highp float n = aureliaNoise(absXZ * AURELIA_PUDDLE_SCALE) * 0.65 + aureliaNoise(absXZ * AURELIA_PUDDLE_SCALE * 3.7 + vec2(11.3, 5.9)) * 0.35;
  float edge = AURELIA_PUDDLE_EDGE - AURELIA_PUDDLE_GROW * wet;
  return smoothstep(edge, edge + 0.07, n) * smoothstep(0.25, 0.6, wet);
}

vec2 aureliaRippleGrad(highp vec2 p, highp float time, float wet) {
  highp vec2 q = p * AURELIA_RIPPLE_DENSITY;
  highp vec2 cell = floor(q);
  vec2 f = fract(q);
  float h1 = aureliaHash(cell);
  float h2 = aureliaHash(cell + vec2(17.3, 3.1));
  float h3 = aureliaHash(cell + vec2(41.7, 9.2));
  float h4 = aureliaHash(cell + vec2(7.7, 23.9));

  vec2 c = vec2(0.3 + 0.4 * h1, 0.3 + 0.4 * h2);
  float life = fract(time * AURELIA_RIPPLE_SPEED + h3);
  vec2 d = f - c;
  float dist = length(d);
  float ring = dist - life * 0.27;
  float fade = (1.0 - life) * (1.0 - life);
  float slope = cos(ring * 60.0) * exp(-ring * ring * 500.0) * fade * step(h4, wet);

  return d / max(dist, 0.001) * slope;
}

float aureliaSplash(highp vec2 p, highp float time, float wet) {
  highp vec2 q = p * AURELIA_SPLASH_DENSITY;
  highp vec2 cell = floor(q);
  vec2 f = fract(q);
  float h1 = aureliaHash(cell + vec2(3.1, 8.7));
  float h2 = aureliaHash(cell + vec2(29.3, 1.9));
  float h3 = aureliaHash(cell + vec2(13.7, 31.1));
  float h4 = aureliaHash(cell + vec2(5.3, 17.9));

  vec2 c = vec2(0.25 + 0.5 * h1, 0.25 + 0.5 * h2);
  float life = fract(time * AURELIA_SPLASH_SPEED + h3);
  float dist = length(f - c) / AURELIA_SPLASH_DENSITY;

  float a = dist / (0.025 + 0.05 * life);
  float jet = exp(-a * a) * pow(1.0 - life, 4.0) * (1.0 - smoothstep(0.15, 0.4, life));

  float b = (dist - 0.02 - life * 0.06) / 0.012;
  float crown = exp(-b * b) * (1.0 - life) * (1.0 - life);

  return (jet + 0.6 * crown) * step(h4, wet * AURELIA_SPLASH_AMOUNT);
}

void aureliaWetSurface(inout vec3 col, float wet, float flatUp, vec3 vdir, vec3 fogColor, vec3 sunDir) {
  col *= 1.0 - AURELIA_WET_DARKEN * wet;

  float cosV = clamp(-vdir.y, 0.0, 1.0);
  float fres = 0.04 + 0.96 * pow(1.0 - cosV, 5.0);
  vec3 r = vec3(vdir.x, abs(vdir.y), vdir.z);

  col = mix(col, aureliaSkyColor(r, fogColor, sunDir), fres * AURELIA_WET_SPEC * wet * flatUp);
}

void aureliaPuddle(inout vec3 col, vec3 vdir, highp vec2 absXZ, float camDis, highp float time, vec3 sunDir, vec3 fogColor, highp vec2 camXZ, float amount, float wet) {
  vec2 g = aureliaRippleGrad(absXZ, time, wet) * AURELIA_RIPPLE_AMP * (1.0 - smoothstep(20.0, 60.0, camDis));
  vec3 n = normalize(vec3(-g.x, 1.0, -g.y));

  float cosV = clamp(dot(n, -vdir), 0.0, 1.0);
  float fres = 0.04 + 0.96 * pow(1.0 - cosV, 5.0);

  vec3 r = reflect(vdir, n);
  r.y = abs(r.y);

  vec3 sky = aureliaSkyColor(r, fogColor, sunDir);
  vec4 cl = aureliaCloudsRaw(r, camXZ, time, sunDir, fogColor, 0.0);
  vec3 refl = mix(sky, cl.rgb, cl.a);

  vec3 dark = col * (1.0 - AURELIA_PUDDLE_DARKEN);
  float k = clamp(fres * AURELIA_PUDDLE_REFLECT, 0.0, 1.0);

  col = mix(col, mix(dark, refl, k), amount);

  float day = mix(0.3, 1.0, smoothstep(-0.1, 0.3, sunDir.y));
  float splash = aureliaSplash(absXZ, time, wet) * (1.0 - smoothstep(15.0, 45.0, camDis));
  col += vec3(0.9, 0.95, 1.0) * (splash * AURELIA_SPLASH_STRENGTH * day * amount);
}

#endif
