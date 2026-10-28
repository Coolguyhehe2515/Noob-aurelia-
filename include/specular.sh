#ifndef AURELIA_SPECULAR_H
#define AURELIA_SPECULAR_H

#include <light.sh>
#include <config.sh>

float aureliaLumaTap(sampler2D tex, vec2 c) {
  return aureliaLuma(texture2DLod(tex, c, 0.0).rgb);
}

vec3 aureliaBevelNormal(sampler2D tex, vec2 uv, float strength) {
  vec2 size = vec2(textureSize(tex, 0));
  vec2 p = uv * size;
  vec2 f = fract(p);
  vec2 c = (floor(p) + 0.5) / size;
  vec2 texel = 1.0 / size;

  float hc = aureliaLumaTap(tex, c);
  float l = aureliaLumaTap(tex, c - vec2(texel.x, 0.0));
  float r = aureliaLumaTap(tex, c + vec2(texel.x, 0.0));
  float t = aureliaLumaTap(tex, c - vec2(0.0, texel.y));
  float b = aureliaLumaTap(tex, c + vec2(0.0, texel.y));

  vec2 w0 = 1.0 - smoothstep(0.0, 0.4, f);
  vec2 w1 = smoothstep(0.6, 1.0, f);

  float gx = (hc - l) * w0.x + (r - hc) * w1.x;
  float gy = (hc - t) * w0.y + (b - hc) * w1.y;

  return normalize(vec3(-vec2(gx, gy) * strength, 1.0));
}

vec3 aureliaApplyTBN(vec3 bn, vec3 N, vec3 dpx, vec3 dpy, vec2 dux, vec2 duy) {
  vec3 dp2perp = cross(dpy, N);
  vec3 dp1perp = cross(N, dpx);
  vec3 T = dp2perp * dux.x + dp1perp * duy.x;
  vec3 B = dp2perp * dux.y + dp1perp * duy.y;
  float invmax = inversesqrt(max(max(dot(T, T), dot(B, B)), 0.000000001));
  return normalize(T * invmax * bn.x + B * invmax * bn.y + N * bn.z);
}

void aureliaSunRelief(inout vec3 lit, sampler2D tex, vec2 uv, vec3 N, vec3 dpx, vec3 dpy, vec2 dux, vec2 duy, vec3 vdir, vec3 sunDir, float gate, float albedoLuma) {
  float lobe = pow(max(dot(reflect(vdir, N), sunDir), 0.0), AURELIA_SPEC_WIDE) * gate;
  if (lobe < 0.02) {
    return;
  }

  vec3 nw = aureliaApplyTBN(aureliaBevelNormal(tex, uv, AURELIA_SPEC_BUMP), N, dpx, dpy, dux, duy);

  float flatL = max(dot(N, sunDir), 0.0);
  float bumpL = max(dot(nw, sunDir), 0.0);
  lit *= max(1.0 + AURELIA_RELIEF * (bumpL - flatL) * lobe, 0.0);

  float spec = pow(max(dot(reflect(vdir, nw), sunDir), 0.0), AURELIA_SPEC_POWER);
  vec3 tint = mix(vec3(1.0, 0.55, 0.25), vec3(1.0, 0.95, 0.85), smoothstep(0.0, 0.35, sunDir.y));
  float gloss = mix(0.4, 1.0, albedoLuma);

  lit += tint * (spec * gloss * gate * AURELIA_SPEC_INTENSITY);
}

#endif
