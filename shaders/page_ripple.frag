#version 460 core

#include <flutter/runtime_effect.glsl>

// A ripple spreads from where the page was touched, like a drop in still
// water. The old page wobbles at the wave and the new one surfaces behind it.

uniform vec2 uSize;
uniform vec4 uRect;     // where the picture sits: left, top, right, bottom
uniform vec4 uPaper;    // the page color around the picture
uniform vec2 uOrigin;
uniform float uProgress; // 0 the old page whole, 1 the new page everywhere
uniform float uHasUnder;
uniform sampler2D uTop;
uniform sampler2D uUnder;

out vec4 fragColor;

bool onPicture(vec2 p) {
  return p.x >= uRect.x && p.y >= uRect.y && p.x <= uRect.z && p.y <= uRect.w;
}

vec2 pictureUv(vec2 p) {
  return (p - uRect.xy) / (uRect.zw - uRect.xy);
}

vec4 topAt(vec2 p) {
  return onPicture(p) ? texture(uTop, pictureUv(p)) : uPaper;
}

vec4 underAt(vec2 p) {
  if (uHasUnder < 0.5) return vec4(0.0);
  return onPicture(p) ? texture(uUnder, pictureUv(p)) : uPaper;
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 away = p - uOrigin;
  float dist = length(away);
  float band = 90.0;
  float front = uProgress * (length(uSize) * 1.1 + band * 2.0) - band;
  float near = exp(-pow((dist - front) / band, 2.0));
  float wave = sin((dist - front) * 0.09) * 12.0 * near;
  vec2 shift = dist > 0.001 ? away / dist * wave : vec2(0.0);

  vec4 top = topAt(p + shift);
  vec4 under = underAt(p + shift * 0.5);
  vec4 color = mix(top, under, smoothstep(-band * 0.4, band * 0.4, front - dist));
  // Light catching the crest.
  color.rgb += vec3(0.07) * max(0.0, sin((dist - front) * 0.09)) * near * color.a;
  fragColor = color;
}
