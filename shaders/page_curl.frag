#version 460 core

#include <flutter/runtime_effect.glsl>

// The page rolls over a cylinder lying across it. Before the cylinder the
// page lies flat; on it the page climbs round, front first and then its
// back; past the top the turned part lies flat again, face down.

uniform vec2 uSize;
uniform vec4 uRect;     // where the picture sits: left, top, right, bottom
uniform vec4 uPaper;    // the page color around the picture
uniform vec2 uAxis;     // a point on the line where the page leaves the table
uniform vec2 uDir;      // unit vector across that line, toward the lifted side
uniform float uRadius;
uniform float uHasUnder;
uniform sampler2D uTop;
uniform sampler2D uUnder;

out vec4 fragColor;

const float PI = 3.14159265;

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

// How far outside the page a point is; negative inside.
float outside(vec2 q) {
  vec2 d = max(-q, q - uSize);
  return max(d.x, d.y);
}

float cover(vec2 q) {
  return clamp(0.5 - outside(q), 0.0, 1.0);
}

vec4 shade(vec4 base, float dark) {
  return vec4(base.rgb * (1.0 - dark), dark + base.a * (1.0 - dark));
}

// The back of the page: the print shows through faintly, mirrored.
vec4 backAt(vec2 q, float light) {
  vec3 c = mix(topAt(q).rgb, uPaper.rgb, 0.88) * light;
  return vec4(c, 1.0);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  float r = max(uRadius, 0.5);
  float d = dot(p - uAxis, uDir);

  vec4 color = underAt(p);

  if (d > 0.0) {
    // The page below the curl, in the shadow of the roll.
    vec2 crest = p + uDir * (r * PI * 0.5 - d);
    float there = 1.0 - smoothstep(-2.0, 28.0, outside(crest));
    float fall = exp(-max(d - r, 0.0) / (r * 0.9 + 8.0));
    color = shade(color, 0.34 * fall * there);
  } else {
    color = topAt(p);
  }

  if (d < 0.0) {
    // The turned part lying on the flat page, and the shadow round it.
    float s = PI * r - d;
    vec2 q = p + uDir * (s - d);
    float lift = 1.0 - smoothstep(0.0, 26.0, outside(q - uDir * 4.0));
    color = shade(color, 0.26 * lift);
    float light = mix(0.97, 1.0, smoothstep(0.0, r, s - PI * r));
    color = mix(color, backAt(q, light), cover(q));
  } else if (d <= r) {
    float theta = asin(clamp(d / r, 0.0, 1.0));
    float edge = clamp(r - d, 0.0, 1.0);
    // Going up the near side, still face up.
    vec2 q1 = p + uDir * (r * theta - d);
    float rise = theta / (PI * 0.5);
    vec4 front = topAt(q1);
    front.rgb *= 1.0 - 0.24 * pow(rise, 2.5);
    color = mix(color, front, cover(q1) * edge);
    // Coming over the top, face down.
    vec2 q2 = p + uDir * (r * (PI - theta) - d);
    float t = 1.0 - rise;
    float light = mix(0.70, 0.97, smoothstep(0.0, 0.7, t));
    light += 0.05 * exp(-pow((t - 0.55) / 0.22, 2.0)) * (1.0 - smoothstep(0.75, 1.0, t));
    color = mix(color, backAt(q2, light), cover(q2) * edge);
  }

  fragColor = color;
}
