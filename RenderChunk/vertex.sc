$input a_color0, a_position, a_texcoord0, a_texcoord1
#ifdef INSTANCING
  $input i_data0, i_data1, i_data2, i_data3
#endif
$output v_color0, v_color1, v_fog, v_texcoord0, v_lightmapUV, v_worldPos

#include <bgfx_shader.sh>
#include <main.sh>

uniform vec4 RenderChunkFogAlpha;
uniform vec4 FogAndDistanceControl;
uniform vec4 ViewPositionAndTime;
uniform vec4 FogColor;
uniform vec4 TimeOfDay;
uniform vec4 CameraPosition;

SAMPLER2D_AUTOREG(s_MatTexture);

void main() {
  #ifdef INSTANCING
    mat4 model = mtxFromCols(i_data0, i_data1, i_data2, i_data3);
  #else
    mat4 model = u_model[0];
  #endif

  vec3 worldPos = mul(model, vec4(a_position, 1.0)).xyz;

  #if !(defined(DEPTH_ONLY_OPAQUE) || defined(DEPTH_ONLY) || defined(INSTANCING))
    float camDis = length(ViewPositionAndTime.xyz - worldPos);

    #ifdef RENDER_AS_BILLBOARDS
      worldPos += vec3(0.5, 0.5, 0.5);
      vec3 viewDir = normalize(ViewPositionAndTime.xyz - worldPos);
      vec3 boardPlane = normalize(vec3(-viewDir.z, 0.0, viewDir.x));
      worldPos -= (((viewDir.zxy * boardPlane.yzx) - (viewDir.yzx * boardPlane.zxy)) *
                   (a_color0.z - 0.5)) +
                   (boardPlane * (a_color0.x - 0.5));
      vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
    #else
      vec4 color = a_color0;
    #endif

    #ifdef SEASONS
      color = vec4(color.www, 1.0);
    #endif

    float relativeDist = camDis / FogAndDistanceControl.z + RenderChunkFogAlpha.x;

    vec2 uv0 = 2.0 * a_texcoord0.xy;
    uv0 = fract(uv0) + ((floor(uv0) - 0.5) / 16384.0);
    vec2 uv1 = fract(a_texcoord1.y * vec2(256.0, 4096.0));

    #if defined(ALPHA_TEST) && !defined(RENDER_AS_BILLBOARDS) && !defined(SEASONS)
      aureliaWave(worldPos, a_color0, a_position.xyz, uv0, camDis, ViewPositionAndTime.w, s_MatTexture);
    #endif

    #ifndef RENDER_AS_BILLBOARDS
      float skyLight = smoothstep(0.5, 0.95, uv1.y);
      color.rgb *= aureliaCloudShadow(worldPos, CameraPosition.xz, ViewPositionAndTime.w, aureliaSunDir(TimeOfDay.x), skyLight);
    #endif

    vec4 fogColor;
    fogColor.rgb = FogColor.rgb;
    fogColor.a = clamp((relativeDist - FogAndDistanceControl.x) / (FogAndDistanceControl.y - FogAndDistanceControl.x), 0.0, 1.0);

    v_color0 = color;
    v_color1 = a_color0;
    v_fog = fogColor;
    v_texcoord0 = uv0;
    v_lightmapUV = uv1;
    v_worldPos = worldPos;
  #endif

  gl_Position = mul(u_viewProj, vec4(worldPos, 1.0));
}
