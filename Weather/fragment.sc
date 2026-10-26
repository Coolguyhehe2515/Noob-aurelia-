$input v_fog, v_occlusionUVHeight, v_texcoord0, v_texcoord1, v_cloudMask

#include <bgfx_shader.sh>
#include <main.sh>

uniform vec4 UVOffsetAndScale;
uniform vec4 OcclusionHeightOffset;

SAMPLER2D_AUTOREG(s_LightingTexture);
SAMPLER2D_AUTOREG(s_OcclusionTexture);
SAMPLER2D_AUTOREG(s_WeatherTexture);

bool isOccluded(const vec2 occlUV, const float occlHeight, const float occlHeightThreshold) {
  #ifdef NO_OCCLUSION
    return false;
  #else
    bool inBounds = occlUV.x >= 0.0 && occlUV.x <= 1.0 && occlUV.y >= 0.0 && occlUV.y <= 1.0;
    #ifdef FLIP_OCCLUSION
      bool isUnder = occlHeight > occlHeightThreshold;
    #else
      bool isUnder = occlHeight < occlHeightThreshold;
    #endif
    return inBounds && isUnder;
  #endif
}

void main() {
  vec4 diffuse = texture2D(s_WeatherTexture, v_texcoord0);
  vec4 occlData = texture2D(s_OcclusionTexture, v_occlusionUVHeight.xy);

  float occlLuminance = fract(occlData.z * 16.0);
  float occlHeightThreshold = ((0.25 * occlData.x) + fract(64.0 * occlData.y)) * 1024.0;
  occlHeightThreshold = (occlHeightThreshold + OcclusionHeightOffset.x) / 255.0;

  vec2 lightingUV = vec2(0.0, 0.0);
  if (!isOccluded(v_occlusionUVHeight.xy, v_occlusionUVHeight.z, occlHeightThreshold)) {
    float mixAmount = clamp((v_occlusionUVHeight.z - occlHeightThreshold) * 25.0, 0.0, 1.0);
    lightingUV = vec2(occlLuminance * (1.0 - mixAmount), 1.0);
  }

  vec3 light = texture2D(s_LightingTexture, lightingUV).rgb;
  vec3 col = diffuse.rgb * light * mix(vec3_splat(1.0), AURELIA_RAIN_COLOR, AURELIA_RAIN_COLOR_MIX);
  col = mix(col, v_fog.rgb, v_fog.a);
  col = aureliaColorGrade(col);

  float alpha = diffuse.a * lightingUV.y * (1.0 - v_fog.a) * v_cloudMask * AURELIA_RAIN_OPACITY;

  gl_FragColor = vec4(col, alpha);
}
