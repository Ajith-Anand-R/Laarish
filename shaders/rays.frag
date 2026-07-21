#version 460 core
#include <flutter/runtime_effect.glsl>

// Volumetric sunlight rays (god rays) fanning from a warm source above the
// top-centre. Transparent overlay — output is premultiplied alpha so it can
// composite over the sky with the default srcOver blend.
uniform float uTime;
uniform vec2 uResolution;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;

  vec2 dir = uv - vec2(0.5, -0.15);       // light source above the frame
  float ang = atan(dir.x, dir.y);
  float rays = sin(ang * 20.0 + uTime * 0.25) * 0.5 + 0.5;
  rays = pow(rays, 3.5);

  float topFade = smoothstep(1.05, 0.0, uv.y);   // strongest near the sun
  float a = rays * topFade * 0.16;

  vec3 warm = vec3(1.0, 0.95, 0.72);
  fragColor = vec4(warm * a, a);
}
