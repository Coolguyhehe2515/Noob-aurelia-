#ifndef AURELIA_LIGHT_H
#define AURELIA_LIGHT_H

#define AURELIA_SUN_INTENSITY 1.0
#define AURELIA_TORCH_COLOR vec3(1.0, 0.72, 0.38)
#define AURELIA_TORCH_INTENSITY 0.15

float aureliaLuma(vec3 c) {
  return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 aureliaLighting(sampler2D lm, vec2 uv, float sunUp) {
  vec3 light = texture2D(lm, vec2(0.0, uv.y)).rgb;

  float skyShare = smoothstep(0.3, 1.0, uv.y);
  light *= mix(1.0, AURELIA_SUN_INTENSITY, skyShare * sunUp);

  float lit = uv.x * uv.x;
  float atten = AURELIA_TORCH_INTENSITY * uv.x / (0.5 - 0.45 * lit);
  vec3 torch = AURELIA_TORCH_COLOR * atten;

  light += torch / (1.0 + aureliaLuma(light));

  return light;
}

#endif
