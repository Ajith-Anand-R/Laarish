#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;

// Cinematic level backdrop: volumetric aurora curtains + water caustics +
// depth haze, tinted to the plant's biome colour.
//
// Uniform contract (set by ShaderView): 0=time, 1..2=resolution, 3..5=biome rgb.
uniform float uTime;
uniform vec2 uResolution;
uniform vec3 uBiome;

out vec4 fragColor;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

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
  mat2 rot = mat2(0.8, -0.6, 0.6, 0.8); // decorrelate the octaves
  for (int i = 0; i < 5; i++) {
    v += a * noise(p);
    p = rot * p * 2.02;
    a *= 0.5;
  }
  return v;
}

// Cheap Voronoi-ish caustic web — the rippling light you get under water.
float caustics(vec2 p, float t) {
  float v = 0.0;
  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    vec2 q = p * (2.0 + fi * 1.4) + vec2(t * (0.20 + fi * 0.07), t * (0.13 - fi * 0.05));
    float a = sin(q.x + sin(q.y + t * 0.5));
    float b = sin(q.y * 1.3 - sin(q.x * 0.9 - t * 0.4));
    v += pow(abs(a * b), 2.2) * (1.0 / (1.0 + fi));
  }
  return v;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution.xy;
  vec2 p = uv;
  p.x *= uResolution.x / uResolution.y;
  float t = uTime * 0.08;

  // Base: deep biome wash, lighter toward the top like a lit sky.
  vec3 deep = uBiome * 0.30;
  vec3 high = mix(uBiome, vec3(1.0, 0.97, 0.88), 0.55);
  vec3 col = mix(high, deep, smoothstep(0.0, 1.15, uv.y));

  // Aurora curtains: vertical ribbons whose horizontal position is warped by
  // fbm, so they wave and fold instead of sliding rigidly.
  float aurora = 0.0;
  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    float warp = fbm(vec2(p.x * 1.6 + fi * 3.7, t * 1.4 + fi));
    float band = abs(p.x - (0.25 + 0.32 * fi) - (warp - 0.5) * 0.55);
    float curtain = smoothstep(0.20, 0.0, band);
    // Curtains are brightest mid-screen and dissolve toward the floor.
    curtain *= smoothstep(1.0, 0.15, uv.y) * (0.55 + 0.45 * sin(t * 2.0 + fi * 2.1));
    aurora += curtain;
  }
  col += aurora * mix(uBiome, vec3(1.0, 0.92, 0.65), 0.45) * 0.32;

  // Caustics on the lower half — reads as sunlight through leaves onto soil.
  float ca = caustics(p, uTime * 0.35) * smoothstep(0.25, 1.0, uv.y);
  col += ca * vec3(1.0, 0.95, 0.75) * 0.16;

  // Slow drifting depth haze so the background never sits perfectly still.
  float haze = fbm(p * 1.4 + vec2(t * 0.6, -t * 0.35));
  col = mix(col, col * 1.18 + uBiome * 0.10, haze * 0.45);

  // Floating dust motes catching the light.
  float motes = 0.0;
  for (int i = 0; i < 6; i++) {
    float fi = float(i);
    vec2 c = vec2(fract(hash(vec2(fi, 3.0)) + t * 0.05 * (0.5 + fi * 0.2)),
                  fract(hash(vec2(fi, 7.0)) - t * (0.06 + 0.03 * fi)));
    float d = length((uv - c) * vec2(uResolution.x / uResolution.y, 1.0));
    motes += smoothstep(0.035, 0.0, d);
  }
  col += motes * vec3(1.0, 0.95, 0.78) * 0.35;

  // Cinematic vignette + a touch of filmic lift so blacks aren't muddy.
  float vig = smoothstep(1.25, 0.35, length(uv - 0.5));
  col *= 0.62 + 0.38 * vig;
  col = pow(clamp(col, 0.0, 1.0), vec3(0.92));

  fragColor = vec4(col, 1.0);
}
