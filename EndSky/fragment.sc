#ifndef INSTANCING
$input v_texcoord0, v_posTime
#endif

#include <bgfx_shader.sh>

#ifndef INSTANCING
  #include <endsky.sh>

  SAMPLER2D_AUTOREG(s_SkyTexture);
#endif

void main() {
  #ifndef INSTANCING
    vec3 color = aureliaEndSky(s_SkyTexture, normalize(v_posTime.xyz));
    gl_FragColor = vec4(color, 1.0);
  #else
    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  #endif
}
