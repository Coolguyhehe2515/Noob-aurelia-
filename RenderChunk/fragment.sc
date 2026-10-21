$input v_color0, v_color1, v_fog, v_texcoord0, v_lightmapUV

#include <bgfx_shader.sh>
#include <tonemap.sh>

SAMPLER2D_AUTOREG(s_MatTexture);
SAMPLER2D_AUTOREG(s_SeasonsTexture);
SAMPLER2D_AUTOREG(s_LightMapTexture);

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

  #if defined(SEASONS) && (defined(OPAQUE) || defined(ALPHA_TEST))
    diffuse.rgb *= mix(vec3(1.0, 1.0, 1.0), texture2D(s_SeasonsTexture, v_color1.xy).rgb * 2.0, v_color1.z);
  #endif

  #if defined(TRANSPARENT) && !(defined(SEASONS) || defined(RENDER_AS_BILLBOARDS))
    diffuse.a *= v_color0.a;
  #else
    diffuse.a = 1.0;
  #endif

  diffuse.rgb *= v_color0.rgb;
  diffuse.rgb *= texture2D(s_LightMapTexture, v_lightmapUV).rgb;
  diffuse.rgb = mix(diffuse.rgb, v_fog.rgb, v_fog.a);

  gl_FragColor = diffuse;
}
