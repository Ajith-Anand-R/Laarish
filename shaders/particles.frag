#version 460 core
#include <flutter/runtime_effect.glsl>

// Floating glowing pollen motes drifting upward. Transparent premultiplied
// overlay. Fixed 28-mote loop (constant bound — Impeller requires it).
uniform float uTime;
uniform vec2 uResolution;

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453);
}

void main() {
  float aspect = uResolution.x / uResolution.y;
  vec2 uv = FlutterFragCoord().xy / uResolution;
  vec2 auv = vec2(uv.x * aspect, uv.y);

  vec3 col = vec3(0.0);
  float alpha = 0.0;

  for (int i = 0; i < 28; i++) {
    float fi = float(i);
    float x = hash(vec2(fi, 1.0));
    float speed = 0.015 + hash(vec2(fi, 2.0)) * 0.05;
    float y = fract(hash(vec2(fi, 3.0)) - uTime * speed);
    float drift = sin(uTime * 0.5 + fi) * 0.015;

    vec2 p = vec2((x + drift) * aspect, y);
    float d = distance(auv, p);
    float glow = 0.0035 / (d + 0.0015);
    glow = clamp(glow, 0.0, 1.0);

    col += vec3(1.0, 0.9, 0.55) * glow;
    alpha += glow;
  }

  alpha = clamp(alpha, 0.0, 0.55);
  fragColor = vec4(col * 0.55, alpha);
}
