#ifndef AURELIA_WAVE_H
#define AURELIA_WAVE_H

#define AURELIA_WAVE_STRENGTH 0.07
#define AURELIA_WAVE_SPEED 2.2
#define AURELIA_WAVE_RANGE 48.0
#define AURELIA_LEAF_STRENGTH 0.04
#define AURELIA_LEAF_SPEED 1.4

void aureliaWave(inout vec3 worldPos, vec4 color, vec3 cPos, vec2 uv0, float camDis, highp float time, sampler2D matTex, highp vec3 camPos) {
  vec3 bPos = fract(cPos);
  bool isTinted = color.r != color.g || color.r != color.b;
  bool isLeaves = (bPos.x + bPos.y + bPos.z) < 0.001;

  if (!isTinted || camDis > AURELIA_WAVE_RANGE) {
    return;
  }

  float fade = 1.0 - smoothstep(0.6, 1.0, camDis / AURELIA_WAVE_RANGE);

  if (isLeaves) {
    highp vec3 ap = floor(worldPos + camPos + 0.5);
    float ph = dot(ap.xz, vec2(0.8, 0.6)) + ap.y * 0.35;
    float gust = sin(time * AURELIA_LEAF_SPEED + ph) + 0.5 * sin(time * AURELIA_LEAF_SPEED * 1.7 + ph * 1.3);
    worldPos.xz += vec2(1.0, 0.6) * gust * AURELIA_LEAF_STRENGTH * fade;
    return;
  }

  float texY = fract(uv0.y * float(textureSize(matTex, 0).y) / 16.0);
  float tip = 1.0 - texY;
  float phase = dot(floor(cPos.xz), vec2(0.8, 0.6));
  float gust = sin(time * AURELIA_WAVE_SPEED + phase) + 0.5 * sin(time * AURELIA_WAVE_SPEED * 1.7 + phase * 1.3);

  worldPos.xz += vec2(1.0, 0.6) * gust * tip * tip * AURELIA_WAVE_STRENGTH * fade;
}

#endif
