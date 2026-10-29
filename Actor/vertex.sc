$input a_position, a_color0, a_texcoord0, a_indices, a_normal
#ifdef INSTANCING
  $input i_data0, i_data1, i_data2
#endif

$output v_color0, v_fog, v_light, v_texcoord0

#include <bgfx_shader.sh>
#include <MinecraftRenderer.Materials/DynamicUtil.dragonh>
#include <MinecraftRenderer.Materials/TAAUtil.dragonh>
#include <main.sh>

uniform vec4 OverlayColor;
uniform vec4 TileLightColor;
uniform vec4 FogColor;
uniform vec4 FogControl;
uniform vec4 TimeOfDay;
uniform vec4 UVAnimation;
uniform mat4 Bones[8];

void main() {
  mat4 World = u_model[0];

  World = mul(World, Bones[int(a_indices)]);

  vec2 texcoord0 = a_texcoord0;
  texcoord0 = applyUvAnimation(texcoord0, UVAnimation);

  vec3 worldPosition;
  #ifdef INSTANCING
    mat4 model = mtxFromCols(i_data0, i_data1, i_data2, vec4(0.0, 0.0, 0.0, 1.0));
    worldPosition = instMul(model, vec4(a_position, 1.0)).xyz;
  #else
    worldPosition = mul(World, vec4(a_position, 1.0)).xyz;
  #endif

  vec4 position = jitterVertexPosition(worldPosition);

  #if !(defined(DEPTH_ONLY_OPAQUE) || defined(DEPTH_ONLY) || defined(INSTANCING))
    float relativeDist = position.z / FogControl.z;

    vec4 fogColor;
    bool uw = aureliaUnderwater(FogColor.rgb, FogControl.xyz);
    float uwB = uw ? AURELIA_UW_BRIGHTNESS : 1.0;
    fogColor.rgb = aureliaIsEnd(FogColor.rgb) ? AURELIA_END_FOG : (uw ? aureliaUnderwaterFog(FogColor.rgb) : FogColor.rgb);
    fogColor.rgb *= uwB;
    fogColor.a = clamp(((uw ? relativeDist * AURELIA_UW_FOG_DENSITY : relativeDist) - FogControl.x) / (FogControl.y - FogControl.x), 0.0, 1.0);

    float lightIntensity = calculateLightIntensity(World, vec4(a_normal.xyz, 0.0), TileLightColor);
    lightIntensity += OverlayColor.a * 0.35;

    v_texcoord0 = texcoord0;
    v_color0 = a_color0;
    v_fog = fogColor;
    vec3 tileLight = TileLightColor.rgb;
    if (aureliaIsEnd(FogColor.rgb)) {
      tileLight = AURELIA_END_AMBIENT * (aureliaLuma(tileLight) / aureliaLuma(AURELIA_END_AMBIENT));
    }
    float sunUp = smoothstep(-0.1, 0.2, aureliaSunDir(TimeOfDay.x).y);
    float skyShare = smoothstep(0.5, 1.0, aureliaLuma(tileLight));
    tileLight *= mix(1.0, AURELIA_SUN_INTENSITY, skyShare * sunUp);
    float warm = clamp((tileLight.r - tileLight.b) * 3.0, 0.0, 1.0);
    tileLight = mix(tileLight, tileLight * (AURELIA_TORCH_COLOR / aureliaLuma(AURELIA_TORCH_COLOR)), warm * AURELIA_ACTOR_TORCH_TINT);
    tileLight *= AURELIA_ACTOR_BRIGHTNESS * uwB;
    aureliaRain = aureliaRainFactor(FogControl.xyz);
    tileLight = mix(tileLight, vec3_splat(aureliaLuma(tileLight)), aureliaRain * AURELIA_ACTOR_RAIN_GRAY);
    tileLight *= 1.0 - AURELIA_ACTOR_RAIN_DARKEN * aureliaRain;
    v_light = vec4(lightIntensity * tileLight, 1.0);
  #endif

  gl_Position = position;
}
