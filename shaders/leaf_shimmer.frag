#version 460 core
#include <flutter/runtime_effect.glsl>

// Living leaf surface: green gradient + fine vein pattern + a diagonal
// specular shimmer band that sweeps across, like sun catching a waxy leaf.
// Opaque — meant as a decorative filled band, not an overlay.
uniform float uTime;
uniform vec2 uResolution;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;

  vec3 green = mix(vec3(0.42, 0.70, 0.28), vec3(0.22, 0.50, 0.17), uv.y);

  float veins = sin((uv.x + uv.y) * 42.0) * 0.5 + 0.5;
  green += veins * 0.03;

  float band = sin((uv.x * 3.0 - uv.y * 2.0) - uTime * 1.1);
  float shimmer = smoothstep(0.94, 1.0, band);
  green += shimmer * vec3(0.9, 1.0, 0.7) * 0.45;

  fragColor = vec4(green, 1.0);
}
