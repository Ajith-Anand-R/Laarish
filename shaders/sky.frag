#version 460 core
#include <flutter/runtime_effect.glsl>

// Animated garden-sunshine sky: vertical gradient + slow-drifting soft cloud
// bands. Uniform order is fixed across all Laarish shaders: 0=uTime,
// 1=uResolution.x, 2=uResolution.y (see ShaderView).
uniform float uTime;
uniform vec2 uResolution;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;

  vec3 top = vec3(0.63, 0.85, 0.98);
  vec3 bottom = vec3(0.99, 0.97, 0.90);
  vec3 col = mix(top, bottom, clamp(uv.y, 0.0, 1.0));

  // two overlapping drifting cloud bands
  float b1 = sin(uv.x * 5.0 + uTime * 0.12) * 0.5 + 0.5;
  float b2 = sin(uv.x * 9.0 - uTime * 0.07 + 1.7) * 0.5 + 0.5;
  float band = smoothstep(0.45, 0.95, b1 * 0.6 + b2 * 0.4) * (1.0 - uv.y);
  col = mix(col, vec3(1.0), band * 0.14);

  fragColor = vec4(col, 1.0);
}
