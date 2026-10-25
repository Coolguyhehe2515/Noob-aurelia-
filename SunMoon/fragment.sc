$input v_texcoord0, v_isSun

#include <bgfx_shader.sh>

#ifndef INSTANCING
  #include <main.sh>

  uniform vec4 SunMoonColor;
  uniform vec4 TimeOfDay;

  SAMPLER2D_AUTOREG(s_SunMoonTexture);
#endif

void main() {
  #ifndef INSTANCING
    float tr = 1.0 - SunMoonColor.a;
    float vis = 1.0 - tr * tr;

    if (v_isSun > 0.5) {
      vec4 sun = aureliaSunDisc(v_texcoord0, aureliaSunDir(TimeOfDay.x).y);
      gl_FragColor = vec4(sun.rgb, sun.a * vis);
    } else {
      vec4 moon = texture2D(s_SunMoonTexture, v_texcoord0);
      moon.rgb *= SunMoonColor.rgb * AURELIA_MOON_BRIGHTNESS;
      moon.rgb = aureliaColorGrade(moon.rgb);
      moon.a *= vis;
      gl_FragColor = moon;
    }
  #else
    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  #endif
}
