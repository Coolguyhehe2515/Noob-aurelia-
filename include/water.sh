#ifndef AURELIA_WATER_H
#define AURELIA_WATER_H

#include <sky.sh>
#include <clouds.sh>

#define AURELIA_WATER_SPEED 1.0
#define AURELIA_WATER_ROUGHNESS 0.14
#define AURELIA_WATER_REFLECT 1.3
#define AURELIA_WATER_CLARITY 0.65
#define AURELIA_WATER_GLINT 2.5

vec2 aureliaWaveGrad(highp vec2 p, vec2 dir, float freq, float speed, float amp, highp float t) {
  return dir * (freq * amp * cos(dot(p, dir) * freq + t * speed));
}

vec3 aureliaWaterNormal(highp vec2 p, highp float time, float rough, float camDis) {
  highp float t = time * AURELIA_WATER_SPEED;
  float mid = 1.0 - smoothstep(30.0, 90.0, camDis);
  float fine = 1.0 - smoothstep(10.0, 40.0, camDis);
  vec2 g = aureliaWaveGrad(p, vec2(0.74, 0.67), 1.9, 1.3, 0.5, t)
         + aureliaWaveGrad(p, vec2(-0.52, 0.85), 3.1, 1.7, 0.3 * mid, t)
         + aureliaWaveGrad(p, vec2(0.93, -0.37), 5.3, 2.3, 0.18 * fine, t)
         + aureliaWaveGrad(p, vec2(-0.28, -0.96), 8.7, 3.1, 0.1 * fine, t);
  return normalize(vec3(-g.x * rough, 1.0, -g.y * rough));
}

void aureliaWater(inout vec3 col, inout float alpha, vec3 vdir, highp vec2 absXZ, float camDis, highp float time, vec3 sunDir, vec3 fogColor, highp vec2 camXZ, float skyVis) {
  float rough = AURELIA_WATER_ROUGHNESS * (1.0 - smoothstep(30.0, 110.0, camDis));
  vec3 n = aureliaWaterNormal(absXZ, time, rough, camDis);

  float cosV = clamp(dot(n, -vdir), 0.0, 1.0);
  float fres = 0.02 + 0.98 * pow(1.0 - cosV, 5.0);

  vec3 r = reflect(vdir, n);
  r.y = abs(r.y);

  vec3 sky = aureliaSkyColor(r, fogColor, sunDir);
  vec4 cl = aureliaCloudsRaw(r, camXZ, time, sunDir, fogColor, 0.0);
  vec3 refl = mix(sky, cl.rgb, cl.a);

  float sunUp = smoothstep(-0.05, 0.08, sunDir.y);
  vec3 sunCol = mix(vec3(1.0, 0.55, 0.25), vec3(1.0, 0.96, 0.88), smoothstep(0.0, 0.4, sunDir.y));
  float glintPow = mix(60.0, 220.0, smoothstep(0.0, 0.5, sunDir.y));
  float glint = pow(max(dot(r, sunDir), 0.0), glintPow) * sunUp * (1.0 - cl.a * 0.8) * skyVis;

  float k = clamp(fres * AURELIA_WATER_REFLECT, 0.0, 1.0) * skyVis;
  col = mix(col, refl, k);
  col += sunCol * glint * AURELIA_WATER_GLINT;

  alpha = clamp(max(alpha * AURELIA_WATER_CLARITY, k), 0.0, 1.0);
  alpha = max(alpha, min(glint * AURELIA_WATER_GLINT, 1.0));
}

#endif
