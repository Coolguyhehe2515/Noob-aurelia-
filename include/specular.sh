#ifndef AURELIA_SPECULAR_H
#define AURELIA_SPECULAR_H

#include <light.sh>

#define AURELIA_SUN_SPEC 1
#define AURELIA_SPEC_WIDE 6.0
#define AURELIA_SPEC_POWER 48.0
#define AURELIA_SPEC_BUMP 3.0
#define AURELIA_SPEC_INTENSITY 0.6

vec3 aureliaBumpNormal(sampler2D tex, vec2 uv, float strength) {
  vec2 texel = 1.0 / vec2(textureSize(tex, 0));
  float l = aureliaLuma(texture2DLod(tex, uv - vec2(texel.x, 0.0), 0.0).rgb);
  float r = aureliaLuma(texture2DLod(tex, uv + vec2(texel.x, 0.0), 0.0).rgb);
  float t = aureliaLuma(texture2DLod(tex, uv - vec2(0.0, texel.y), 0.0).rgb);
  float b = aureliaLuma(texture2DLod(tex, uv + vec2(0.0, texel.y), 0.0).rgb);
  return normalize(vec3(-vec2(r - l, b - t) * strength, 1.0));
}

void aureliaSunSpecular(inout vec3 lit, sampler2D tex, vec2 uv, vec3 vdir, vec3 sunDir, float gate, float albedoLuma) {
  vec3 flatRefl = vec3(vdir.x, -vdir.y, vdir.z);
  float wide = pow(max(dot(flatRefl, sunDir), 0.0), AURELIA_SPEC_WIDE);
  if (wide < 0.02) {
    return;
  }

  vec3 bn = aureliaBumpNormal(tex, uv, AURELIA_SPEC_BUMP);
  vec3 n = normalize(vec3(bn.x, bn.z, bn.y));
  vec3 refl = reflect(vdir, n);
  float spec = pow(max(dot(refl, sunDir), 0.0), AURELIA_SPEC_POWER);

  vec3 tint = mix(vec3(1.0, 0.55, 0.25), vec3(1.0, 0.95, 0.85), smoothstep(0.0, 0.35, sunDir.y));
  float gloss = mix(0.4, 1.0, albedoLuma);

  lit += tint * (spec * gloss * gate * AURELIA_SPEC_INTENSITY);
}

#endif
