$input a_position, a_texcoord0
$output v_texcoord0, v_isSun

#include <bgfx_shader.sh>
#include <main.sh>

uniform vec4 TimeOfDay;

void main() {
  v_texcoord0 = a_texcoord0;
  v_isSun = 0.0;

  #ifndef INSTANCING
    vec2 dir = mul(u_model[0], vec4(0.0, 0.0, 0.0, 1.0)).xy;
    float st = 6.2831853 * TimeOfDay.x + 1.5707963;
    bool isSun = dot(vec2(cos(st), sin(st)), dir) > 0.0;

    vec3 sunDir = aureliaSunDir(TimeOfDay.x);
    vec3 side = vec3(sunDir.y, -sunDir.x, 0.0);
    vec3 up = vec3(0.0, 0.0, 1.0);

    vec2 p = a_position.xz;
    vec3 center;
    float size;
    if (isSun) {
      center = sunDir * 300.0;
      size = AURELIA_SUN_SIZE;
      v_isSun = 1.0;
    } else {
      center = -sunDir * 300.0;
      size = AURELIA_MOON_SIZE;
      p.x = -p.x;
    }

    vec3 wpos = center + (side * p.x + up * p.y) * 70.0 * size;
    gl_Position = mul(u_viewProj, vec4(wpos, 1.0));
  #else
    gl_Position = vec4(0.0, 0.0, 0.0, 0.0);
  #endif
}
