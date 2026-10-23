#ifndef AURELIA_TONEMAP_H
#define AURELIA_TONEMAP_H

#define AURELIA_EXPOSURE 1.1
#define AURELIA_SATURATION 1.3

#define UCH_MAX 1.0
#define UCH_CONTRAST 1.1
#define UCH_LINEAR_START 0.22
#define UCH_LINEAR_LEN 0.4
#define UCH_BLACK 1.30
#define UCH_PEDESTAL 0.0

vec3 aureliaTonemap(vec3 x) {
  float P = UCH_MAX;
  float a = UCH_CONTRAST;
  float m = UCH_LINEAR_START;
  float l = UCH_LINEAR_LEN;
  float c = UCH_BLACK;
  float b = UCH_PEDESTAL;

  float l0 = ((P - m) * l) / a;
  float S0 = m + l0;
  float S1 = m + a * l0;
  float C2 = (a * P) / (P - S1);
  float CP = -C2 / P;

  vec3 w0 = vec3_splat(1.0) - smoothstep(vec3_splat(0.0), vec3_splat(m), x);
  vec3 w2 = step(vec3_splat(S0), x);
  vec3 w1 = vec3_splat(1.0) - w0 - w2;

  vec3 T = m * pow(x / m, vec3_splat(c)) + vec3_splat(b);
  vec3 L = vec3_splat(m) + a * (x - vec3_splat(m));
  vec3 S = vec3_splat(P) - (P - S1) * exp(CP * (x - vec3_splat(S0)));

  return clamp(T * w0 + L * w1 + S * w2, 0.0, 1.0);
}

vec3 aureliaSaturate(vec3 c, float s) {
  float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
  return mix(vec3_splat(l), c, s);
}

vec3 aureliaColorGrade(vec3 c) {
  c *= c;
  c *= AURELIA_EXPOSURE;
  c = aureliaTonemap(c);
  c = sqrt(c);
  return aureliaSaturate(c, AURELIA_SATURATION);
}

#endif
