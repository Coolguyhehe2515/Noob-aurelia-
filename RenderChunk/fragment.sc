$input v_color0, v_color1, v_fog, v_texcoord0, v_lightmapUV

#include <bgfx_shader.sh>
#include <main.sh>

SAMPLER2D_AUTOREG(s_MatTexture);
SAMPLER2D_AUTOREG(s_SeasonsTexture);
SAMPLER2D_AUTOREG(s_LightMapTexture);

#define AURELIA_GLOW_ALPHA 252.0
#define AURELIA_GLOW_STRENGTH 1.3
#define AURELIA_AO_STRENGTH 1.5
#define AURELIA_SHADE_COLOR vec3(0.78, 0.86, 1.0)

void main() {
  #if defined(DEPTH_ONLY_OPAQUE) || defined(DEPTH_ONLY) || defined(INSTANCING)
    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    return;
  #endif

  vec4 diffuse = texture2D(s_MatTexture, v_texcoord0);

  #ifdef ALPHA_TEST
    if (diffuse.a < 0.5) {
      discard;
    }
  #endif

  float emissive = 0.0;
  #if defined(OPAQUE) || defined(ALPHA_TEST)
    emissive = 1.0 - step(0.5, abs(diffuse.a * 255.0 - AURELIA_GLOW_ALPHA));
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

  vec3 lit = diffuse.rgb * shaded * texture2D(s_LightMapTexture, v_lightmapUV).rgb;
  lit *= mix(vec3_splat(1.0), AURELIA_SHADE_COLOR, shadow);

  vec3 glow = diffuse.rgb * AURELIA_GLOW_STRENGTH;
  diffuse.rgb = mix(lit, glow, emissive);

  diffuse.rgb = mix(diffuse.rgb, v_fog.rgb, v_fog.a);
  diffuse.rgb = aureliaColorGrade(diffuse.rgb);

  gl_FragColor = diffuse;
}
