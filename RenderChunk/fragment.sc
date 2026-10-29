$input v_color0, v_color1, v_fog, v_texcoord0, v_lightmapUV, v_worldPos, v_chunkPos

#include <bgfx_shader.sh>
#include <main.sh>

SAMPLER2D_AUTOREG(s_MatTexture);
SAMPLER2D_AUTOREG(s_SeasonsTexture);
SAMPLER2D_AUTOREG(s_LightMapTexture);

#ifdef AURELIA_CAUSTIC_TEXTURE
  SAMPLER2D_AUTOREG(s_CausticTex);
#endif

uniform vec4 ViewPositionAndTime;
uniform vec4 TimeOfDay;
uniform vec4 CameraPosition;
uniform vec4 FogColor;
uniform vec4 FogAndDistanceControl;

#ifdef AURELIA_CAUSTIC_TEXTURE
float aureliaCausticSample(highp vec2 absXZ, highp float time) {
  highp vec2 uv = fract(absXZ * AURELIA_CAUSTIC_SCALE);
  highp float ft = time * AURELIA_CAUSTIC_FPS;
  float f0 = mod(floor(ft), 32.0);
  float f1 = mod(f0 + 1.0, 32.0);
  highp float x = (uv.x * 127.0 + 0.5) / 128.0;
  highp float y0 = (f0 * 128.0 + 0.5 + uv.y * 127.0) / 4096.0;
  highp float y1 = (f1 * 128.0 + 0.5 + uv.y * 127.0) / 4096.0;
  float a = texture2D(s_CausticTex, vec2(x, y0)).r;
  float b = texture2D(s_CausticTex, vec2(x, y1)).r;
  return mix(a, b, fract(ft));
}
#else
float aureliaCausticSample(highp vec2 absXZ, highp float time) {
  highp vec2 q = absXZ * 0.8;
  highp float t = time * 0.5;
  float a = 1.0 - abs(aureliaNoise(q + vec2(t, t * 0.6)) * 2.0 - 1.0);
  float b = 1.0 - abs(aureliaNoise(q * 1.37 + vec2(-t * 0.8, t) + 7.7) * 2.0 - 1.0);
  return clamp(pow(a, 9.0) + pow(b, 9.0), 0.0, 1.0);
}
#endif

void main() {
  #if defined(DEPTH_ONLY_OPAQUE) || defined(DEPTH_ONLY) || defined(INSTANCING)
    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    return;
  #endif

  aureliaRain = aureliaRainFactor(FogAndDistanceControl.xyz);
  bool isEnd = aureliaIsEnd(FogColor.rgb);

  vec4 diffuse = texture2D(s_MatTexture, v_texcoord0);

  #ifdef ALPHA_TEST
    if (diffuse.a < 0.5) {
      discard;
    }
  #endif

  float emissive = 0.0;
  float metal = 0.0;

  #ifdef OPAQUE
    float alpha255 = diffuse.a * 255.0;
    emissive = clamp((255.0 - alpha255) / 3.0, 0.0, 1.0) * step(249.0, alpha255);
    metal = clamp((250.0 - alpha255) / 10.0, 0.0, 1.0);
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
  float shadow = (1.0 - smoothstep(0.55, 0.95, v_lightmapUV.y)) * (1.0 - v_lightmapUV.x) * (isEnd ? 0.0 : 1.0);
  float skyVis = smoothstep(0.4, 0.9, v_lightmapUV.y);

  float sunUp = smoothstep(-0.1, 0.2, aureliaSunDir(TimeOfDay.x).y);
  vec3 lightCol = isEnd ? aureliaEndLighting(v_lightmapUV.x) : aureliaLighting(s_LightMapTexture, v_lightmapUV, sunUp);
  vec3 lit = diffuse.rgb * shaded * lightCol;
  lit *= mix(vec3_splat(1.0), AURELIA_SHADE_COLOR, shadow);

  vec2 screenuv = gl_FragCoord.xy / max(u_viewRect.zw, vec2(1.0));
  float dist = distance(screenuv, vec2(0.5));
  float vignette = pow(1.0 - smoothstep(0.25, 0.8, dist), 1.8);
  lit *= mix(1.0, vignette, shadow * AURELIA_VIGNETTE_STRENGTH);

  #if defined(OPAQUE) || (defined(TRANSPARENT) && !(defined(SEASONS) || defined(RENDER_AS_BILLBOARDS)))
    vec3 dpx = dFdx(v_worldPos);
    vec3 dpy = dFdy(v_worldPos);
    vec2 dux = dFdx(v_texcoord0);
    vec2 duy = dFdy(v_texcoord0);
    vec3 fnc = cross(dpx, dpy);
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

    #ifdef AURELIA_CAUSTICS
      bool blockUnderWater = v_lightmapUV.y < 0.9 && abs((2.0 * v_chunkPos.y - 15.0) / 16.0 - v_lightmapUV.y) < AURELIA_UW_EPS;
      bool camUnderwater = aureliaUnderwater(FogColor.rgb, FogAndDistanceControl.xyz);
      float causGate = float(blockUnderWater || camUnderwater) * smoothstep(0.3, 0.9, abs(fn.y)) * (isEnd ? 0.0 : 1.0);

      if (causGate > 0.01) {
        float caus = aureliaCausticSample(v_worldPos.xz + CameraPosition.xz, ViewPositionAndTime.w);
        lit += AURELIA_CAUSTIC_TINT * (caus * AURELIA_CAUSTIC_INTENSITY * 0.45 * causGate * mix(0.35, 1.0, sunUp));
      }
    #endif

    #ifdef AURELIA_METAL
      if (metal > 0.01) {
        vec3 mN = dot(fn, vdir) > 0.0 ? -fn : fn;
        vec3 mr = reflect(vdir, mN);
        mr.y = abs(mr.y);

        vec3 sunD = aureliaSunDir(TimeOfDay.x);
        vec3 skyR = aureliaSkyColor(mr, FogColor.rgb, sunD);
        vec4 clR = aureliaCloudsRaw(mr, CameraPosition.xz, ViewPositionAndTime.w, sunD, FogColor.rgb, 0.0);
        vec3 envR = isEnd ? AURELIA_END_AMBIENT * 0.8 : mix(skyR, clR.rgb, clR.a);

        float cosM = clamp(dot(mN, -vdir), 0.0, 1.0);
        float fresM = 0.55 + 0.45 * pow(1.0 - cosM, 5.0);
        vec3 tintM = mix(vec3_splat(1.0), diffuse.rgb / max(max(diffuse.r, max(diffuse.g, diffuse.b)), 0.001), AURELIA_METAL_TINT);
        float envVis = mix(0.25, 1.0, skyVis);
        vec3 refl = envR * tintM * (0.5 + 0.9 * aureliaLuma(diffuse.rgb)) * envVis;

        vec3 sunTintM = mix(vec3(1.0, 0.55, 0.25), vec3(1.0, 0.95, 0.85), smoothstep(0.0, 0.35, sunD.y));
        refl += sunTintM * pow(max(dot(mr, sunD), 0.0), AURELIA_METAL_SHINE) * sunUp * skyVis * (isEnd ? 0.0 : 1.0);

        lit = mix(lit, lit * (1.0 - AURELIA_METAL_DARKEN) + refl * AURELIA_METAL_REFLECT * fresM, metal);
      }
    #endif

    #ifdef AURELIA_SUN_SPEC
      vec3 specN = dot(fn, vdir) > 0.0 ? -fn : fn;
      float specGate = skyVis * sunUp * (1.0 - aureliaRain) * (1.0 - smoothstep(0.6, 1.0, camDis / AURELIA_RELIEF_RANGE)) * (isEnd ? 0.0 : 1.0);

      if (specGate > 0.01) {
        aureliaSunRelief(lit, s_MatTexture, v_texcoord0, specN, dpx, dpy, dux, duy, vdir, aureliaSunDir(TimeOfDay.x), specGate, aureliaLuma(diffuse.rgb));
      }
    #endif
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

  color = mix(color, isEnd ? AURELIA_END_FOG : v_fog.rgb, v_fog.a);

  #if defined(AURELIA_GODRAYS) && (defined(OPAQUE) || (defined(TRANSPARENT) && !(defined(SEASONS) || defined(RENDER_AS_BILLBOARDS))))
    if (aureliaUnderwater(FogColor.rgb, FogAndDistanceControl.xyz)) {
      color += aureliaUnderwaterRays(vdir, aureliaSunDir(TimeOfDay.x), ViewPositionAndTime.w, camDis) * smoothstep(0.05, 0.6, v_lightmapUV.y) * (1.0 - aureliaRain);
    }
  #endif

    if (aureliaUnderwater(FogColor.rgb, FogAndDistanceControl.xyz)) {
    color *= AURELIA_UW_BRIGHTNESS;
  }

  color = aureliaColorGrade(color);

  gl_FragColor = vec4(color, alpha);
}
