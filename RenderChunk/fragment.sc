$input v_color0, v_color1, v_fog, v_texcoord0, v_lightmapUV, v_worldPos

#include <bgfx_shader.sh>
#include <main.sh>

SAMPLER2D_AUTOREG(s_MatTexture);
SAMPLER2D_AUTOREG(s_SeasonsTexture);
SAMPLER2D_AUTOREG(s_LightMapTexture);

uniform vec4 ViewPositionAndTime;
uniform vec4 TimeOfDay;
uniform vec4 CameraPosition;
uniform vec4 FogColor;
uniform vec4 FogAndDistanceControl;

#define AURELIA_GLOW_STRENGTH 1.3
#define AURELIA_AO_STRENGTH 1.5
#define AURELIA_SHADE_COLOR vec3(0.78, 0.86, 1.0)

void main() {
  #if defined(DEPTH_ONLY_OPAQUE) || defined(DEPTH_ONLY) || defined(INSTANCING)
    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    return;
  #endif

  aureliaRain = aureliaRainFactor(FogAndDistanceControl.xyz);

  vec4 diffuse = texture2D(s_MatTexture, v_texcoord0);

  #ifdef ALPHA_TEST
    if (diffuse.a < 0.5) {
      discard;
    }
  #endif

  float emissive = 0.0;
  #ifdef OPAQUE
    float alpha255 = diffuse.a * 255.0;
    emissive = clamp((255.0 - alpha255) / 3.0, 0.0, 1.0) * step(249.0, alpha255);
  #endif

  #if defined(SEASONS) && (defined(OPAQUE) || defined(ALPHA_TEST))
    diffuse.rgb *= mix(vec3(1.0, 1.0, 1.0), texture2D(s_SeasonsTexture, v_color1.xy).rgb * 2.0, v_color1.z);
  #endif

  #if defined(TRANSPARENT) && !(defined(SEASONS) || defined(RENDER_AS_BILLBOARDS))
    diffuse.a *= v_color0.a;
  #else
    diffuse.a = 1.0;
  #endif

  float shadeMax = max(v_color0.r, max(v_color0.g, v_color0.b));
  vec3 shaded = v_color0.rgb * pow(shadeMax, AURELIA_AO_STRENGTH - 1.0);
  float shadow = (1.0 - smoothstep(0.55, 0.95, v_lightmapUV.y)) * (1.0 - v_lightmapUV.x);
  float skyVis = smoothstep(0.4, 0.9, v_lightmapUV.y);

  float sunUp = smoothstep(-0.1, 0.2, aureliaSunDir(TimeOfDay.x).y);
  vec3 lit = diffuse.rgb * shaded * aureliaLighting(s_LightMapTexture, v_lightmapUV, sunUp);
  lit *= mix(vec3_splat(1.0), AURELIA_SHADE_COLOR, shadow);

  #if defined(OPAQUE) || (defined(TRANSPARENT) && !(defined(SEASONS) || defined(RENDER_AS_BILLBOARDS)))
    vec3 fnc = cross(dFdx(v_worldPos), dFdy(v_worldPos));
    vec3 fn = fnc / max(length(fnc), 0.000001);
    vec3 vdir = normalize(v_worldPos - ViewPositionAndTime.xyz);
    float camDis = length(v_worldPos - ViewPositionAndTime.xyz);
  #endif

  #ifdef OPAQUE
    float wet = aureliaWetness(aureliaRain) * skyVis;
    if (wet > 0.001) {
      float flatUp = smoothstep(0.85, 0.95, abs(fn.y)) * step(vdir.y, 0.0);
      aureliaWetSurface(lit, wet, flatUp, vdir, FogColor.rgb, aureliaSunDir(TimeOfDay.x));

      highp vec2 absXZ = v_worldPos.xz + CameraPosition.xz;
      float puddle = aureliaPuddleMask(absXZ, wet) * flatUp;
      if (puddle > 0.01) {
        aureliaPuddle(lit, vdir, absXZ, camDis, ViewPositionAndTime.w, aureliaSunDir(TimeOfDay.x), FogColor.rgb, CameraPosition.xz, puddle, wet);
      }
    }
  #endif

  vec3 glow = diffuse.rgb * AURELIA_GLOW_STRENGTH;
  vec3 color = mix(lit, glow, emissive);
  float alpha = diffuse.a;

  #if defined(TRANSPARENT) && !(defined(SEASONS) || defined(RENDER_AS_BILLBOARDS))
    bool isWater = v_color1.b > 0.3 && v_color1.a < 0.95;

    if (isWater && abs(fn.y) > 0.9 && vdir.y < 0.0) {
      aureliaWater(color, alpha, vdir, v_worldPos.xz + CameraPosition.xz, camDis, ViewPositionAndTime.w, aureliaSunDir(TimeOfDay.x), FogColor.rgb, CameraPosition.xz, skyVis);
    }
  #endif

  color = mix(color, v_fog.rgb, v_fog.a);
  color = aureliaColorGrade(color);

  gl_FragColor = vec4(color, alpha);
}
