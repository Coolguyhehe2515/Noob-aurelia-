#ifndef AURELIA_LIGHT_H
#define AURELIA_LIGHT_H

#define AURELIA_SUN_INTENSITY 1.0
#define AURELIA_TORCH_COLOR vec3(1.0, 0.62, 0.30)
#define AURELIA_TORCH_INTENSITY 1.0

float aureliaLuma(vec3 c) {
  return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 aureliaLighting(sampler2D lm, vec2 uv, float sunUp) {
  vec3 combined = texture2D(lm, uv).rgb;
  vec3 ambient = texture2D(lm, vec2(0.0, 0.0)).rgb;
  vec3 torchGain = max(texture2D(lm, vec2(uv.x, 0.0)).rgb - ambient, vec3_splat(0.0));
  vec3 skyGain = max(texture2D(lm, vec2(0.0, uv.y)).rgb - ambient, vec3_splat(0.0));

  float torchL = aureliaLuma(torchGain);
  float skyL = aureliaLuma(skyGain);
  float torchShare = torchL / max(torchL + skyL, 0.001);

  vec3 hue = torchGain / max(torchL, 0.001);
  vec3 target = AURELIA_TORCH_COLOR / max(aureliaLuma(AURELIA_TORCH_COLOR), 0.001);
  vec3 tint = min(target / max(hue, vec3_splat(0.05)), vec3_splat(3.0));

  vec3 light = combined * mix(vec3_splat(1.0), tint, torchShare);
  light *= mix(1.0, AURELIA_TORCH_INTENSITY, torchShare);

  float skyShare = (1.0 - torchShare) * smoothstep(0.3, 1.0, uv.y);
  light *= mix(1.0, AURELIA_SUN_INTENSITY, skyShare * sunUp);

  return light;
}

#endif
