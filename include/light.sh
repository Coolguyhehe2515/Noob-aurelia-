#ifndef AURELIA_LIGHT_H
#define AURELIA_LIGHT_H

#define AURELIA_SUN_INTENSITY 1.0
#define AURELIA_TORCH_COLOR vec3(1.0, 0.72, 0.38)
#define AURELIA_TORCH_INTENSITY 0.15
#define AURELIA_END_AMBIENT vec3(0.9, 0.78, 0.58)
#define AURELIA_END_FOG vec3(0.26, 0.24, 0.17)

float aureliaLuma(vec3 c) {
  return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

bool aureliaIsNether(vec3 fogColor, vec2 fogControl) {
  float expectedFogX = 0.029 + 0.09 * fogControl.y * fogControl.y;
  bool netherFogCtrl = fogControl.x < 0.14 && abs(fogControl.x - expectedFogX) < 0.02;
  bool netherFogCol = (fogColor.r + fogColor.g) > 0.0;
  bool underLava = fogControl.x == 0.0 && fogColor.b == 0.0 && fogColor.g < 0.18 && fogColor.r - fogColor.g > 0.1;
  return (netherFogCtrl && netherFogCol) || underLava;
}

bool aureliaIsEnd(vec3 fogColor) {
  return fogColor.r == fogColor.b && (fogColor.r - fogColor.g > 0.24 || (fogColor.g == 0.0 && fogColor.r > 0.1));
}

vec3 aureliaTorch(float uvx) {
  float lit = uvx * uvx;
  float atten = AURELIA_TORCH_INTENSITY * uvx / (0.5 - 0.45 * lit);
  return AURELIA_TORCH_COLOR * atten;
}

vec3 aureliaLighting(sampler2D lm, vec2 uv, float sunUp) {
  vec3 light = texture2D(lm, vec2(0.0, uv.y)).rgb;

  float skyShare = smoothstep(0.3, 1.0, uv.y);
  light *= mix(1.0, AURELIA_SUN_INTENSITY, skyShare * sunUp);

  light += aureliaTorch(uv.x) / (1.0 + aureliaLuma(light));

  return light;
}

vec3 aureliaEndLighting(float uvx) {
  vec3 light = AURELIA_END_AMBIENT;
  light += aureliaTorch(uvx) / (1.0 + aureliaLuma(light));
  return light;
}

#endif
