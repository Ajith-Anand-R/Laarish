#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;

// Uniform contract (set by ShaderView): 0=time, 1..2=resolution, 3..5=biome rgb.
uniform float uTime;
uniform vec2 uResolution;
uniform vec3 uBiome;

out vec4 fragColor;

float hash(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453); }

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 5; i++) {
    v += a * noise(p);
    p *= 2.0;
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution.xy;
  vec2 p = uv;
  p.x *= uResolution.x / uResolution.y;
  float t = uTime * 0.06;

  // Domain-warped flowing energy field — the "living" motion.
  vec2 q = vec2(fbm(p * 2.0 + vec2(0.0, t)), fbm(p * 2.0 + vec2(5.2, -t)));
  float f = fbm(p * 3.0 + q * 1.7 + vec2(t * 0.5, t * 0.3));

  // Vertical depth: lighter biome sky up top, richer biome soil below.
  vec3 top = uBiome * 0.7 + 0.32;
  vec3 bottom = uBiome * 0.5;
  vec3 col = mix(top, bottom, uv.y);

  // Flowing colour bands + warm light pockets from the noise.
  col += (f - 0.5) * uBiome * 0.55;
  col = mix(col, vec3(1.0, 0.95, 0.72), smoothstep(0.55, 0.92, f) * 0.28);

  // Soft god-rays streaming from above.
  float ray = 0.0;
  for (int i = 0; i < 4; i++) {
    float fi = float(i);
    ray += smoothstep(0.015, 0.0, abs(sin(uv.x * 3.0 + fi * 1.7 + t * 0.8)) - 0.986);
  }
  col += ray * vec3(1.0, 0.9, 0.6) * (1.0 - uv.y) * 0.16;

  // Drifting bokeh motes rising through the scene.
  float b = 0.0;
  for (int i = 0; i < 7; i++) {
    float fi = float(i);
    vec2 c = vec2(hash(vec2(fi, 1.0)), fract(hash(vec2(fi, 2.0)) + t * (0.10 + 0.05 * fi)));
    c.y = 1.0 - c.y;
    float d = length((uv - c) * vec2(uResolution.x / uResolution.y, 1.0));
    b += smoothstep(0.045, 0.0, d) * 0.55;
  }
  col += b * vec3(1.0, 0.92, 0.7);

  // Cinematic vignette.
  float vig = smoothstep(1.15, 0.3, length(uv - 0.5));
  col *= 0.68 + 0.32 * vig;

  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
