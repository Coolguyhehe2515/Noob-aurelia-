$input a_color0, a_position
#ifdef INSTANCING
  $input i_data0, i_data1, i_data2, i_data3
#endif
$output v_color0

#include <bgfx_shader.sh>
#include <main.sh>

void main() {
  #ifdef INSTANCING
    mat4 model = mtxFromCols(i_data0, i_data1, i_data2, i_data3);
  #else
    mat4 model = u_model[0];
  #endif

  vec3 pos = a_position;
  vec4 apos = vec4(pos.xz - 32.0, 1.0, 1.0);
  apos.x *= pos.y - 0.5;
  apos.xy = clamp(apos.xy, -1.0, 1.0);

  #if BGFX_SHADER_LANGUAGE_GLSL
    float h = model[3][1];
  #else
    float h = model[1][3];
  #endif
  h = clamp(0.002 * h, 0.0, 1.0);

  vec3 worldPos = mul(u_invViewProj, apos).xyz;

  v_color0 = vec4(worldPos, h);
  gl_Position = apos;
}
