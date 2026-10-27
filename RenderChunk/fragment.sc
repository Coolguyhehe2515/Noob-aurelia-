$input v_color0, v_color1, v_fog, v_texcoord0, v_lightmapUV, v_worldPos, v_chunkPos

#include <bgfx_shader.sh>
#include <main.sh>

SAMPLER2D_AUTOREG(s_MatTexture);
SAMPLER2D_AUTOREG(s_SeasonsTexture);
SAMPLER2D_AUTOREG(s_LightMapTexture);

#define AURELIA_CAUSTICS 0
#define AURELIA_CAUSTIC_TEXTURE 1

#if AURELIA_CAUSTIC_TEXTURE
  SAMPLER2D_AUTOREG(s_CausticsTexture);
#endif

uniform vec4 ViewPositionAndTime;
uniform vec4 TimeOfDay;
uniform vec4 CameraPosition;
uniform vec4 FogColor;
uniform vec4 FogAndDistanceControl;

#define AURELIA_GLOW_STRENGTH 1.3
#define AURELIA_AO_STRENGTH 1.5
#define AURELIA_SHADE_COLOR vec3(0.78, 0.86, 1.0)
#define AURELIA_VIGNETTE_STRENGTH 1.0
#define AURELIA_CAUSTIC_STRENGTH 0.9
#define AURELIA_CAUSTIC_SCALE 0.8
#define AURELIA_CAUSTIC_SPEED 0.5
#define AURELIA_CAUSTIC_SHARP 9.0
#define AURELIA_CAUSTIC_TEX_SCALE 0.15
#define AURELIA_CAUSTIC_TEX_SPEED 0.02
#define AURELIA_UW_EPS 0.004

float aureliaCausticPattern(highp vec2 p, highp float time) {
  #if AURELIA_CAUSTIC_TEXTURE
    highp vec2 uv = p * AURELIA_CAUSTIC_TEX_SCALE + vec2(time * AURELIA_CAUSTIC_TEX_SPEED);
    return texture2D(s_CausticsTexture, uv).r;
  #else
    highp vec2 q = p * AURELIA_CAUSTIC_SCALE;
    highp float t = time * AURELIA_CAUSTIC_SPEED;
    float a = 1.0 - abs(aureliaNoise(q + vec2(t, t * 0.6)) * 2.0 - 1.0);
    float b = 1.0 - abs(aureliaNoise(q * 1.37 + vec2(-t * 0.8, t) + 7.7) * 2.0 - 1.0);
    return clamp(pow(a, AURELIA_CAUSTIC_SHARP) + pow(b, AURELIA_CAUSTIC_SHARP), 0.0, 1.0);
  #endif
}

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
  float shadow = (1.0 - smoothstep(0.55, 0.95, v_lightmapUV.y)) * (1.0 - v_lightmapUV.x) * (isEnd ? 0.0 : 1.0);
  float skyVis = smoothstep(0.4, 0.9, v_lightmapUV.y);

  float sunUp = smoothstep(-0.1, 0.2, aureliaSunDir(TimeOfDay.x).y);
  vec3 lightCol = isEnd ? aureliaEndLighting(v_lightmapUV.x) : aureliaLighting(s_LightMapTexture, v_lightmapUV, sunUp);
  vec3 lit = diffuse.rgb * shaded * lightCol;
  lit *= mix(vec3_splat(1.0), AURELIA_SHADE_COLOR, shadow);

  vec2 screenuv = gl_FragCoord.xy / u_viewRect.zw;
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

    #if AURELIA_CAUSTICS
      bool blockUnderWater = v_lightmapUV.y < 0.9 && abs((2.0 * v_chunkPos.y - 15.0) / 16.0 - v_lightmapUV.y) < AURELIA_UW_EPS;
      bool camUnderwater = aureliaUnderwater(FogColor.rgb, FogAndDistanceControl.xyz);
      float causGate = float(blockUnderWater || camUnderwater) * smoothstep(0.3, 0.9, abs(fn.y)) * sunUp * (1.0 - aureliaRain) * (isEnd ? 0.0 : 1.0);
      if (causGate > 0.01) {
        float caus = aureliaCausticPattern(v_worldPos.xz + CameraPosition.xz, ViewPositionAndTime.w);
        lit *= 1.0 + caus * AURELIA_CAUSTIC_STRENGTH * causGate;
      }
    #endif

    #if AURELIA_SUN_SPEC
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
    } else if (isWater && abs(fn.y) > 0.9 && vdir.y > 0.0 && aureliaUnderwater(FogColor.rgb, FogAndDistanceControl.xyz)) {
      aureliaSnellWindow(color, alpha, vdir, v_worldPos.xz + CameraPosition.xz, camDis, ViewPositionAndTime.w, aureliaSunDir(TimeOfDay.x), FogColor.rgb, CameraPosition.xz);
    }
  #endif

  color = mix(color, isEnd ? AURELIA_END_FOG : v_fog.rgb, v_fog.a);
  #if AURELIA_GODRAYS && (defined(OPAQUE) || (defined(TRANSPARENT) && !(defined(SEASONS) || defined(RENDER_AS_BILLBOARDS))))
    if (aureliaUnderwater(FogColor.rgb, FogAndDistanceControl.xyz)) {
      color += aureliaUnderwaterRays(vdir, aureliaSunDir(TimeOfDay.x), ViewPositionAndTime.w, camDis) * smoothstep(0.05, 0.6, v_lightmapUV.y) * (1.0 - aureliaRain);
    }
  #endif

  color = aureliaColorGrade(color);

  gl_FragColor = vec4(color, alpha);
}
