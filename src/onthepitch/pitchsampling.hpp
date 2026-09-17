#ifndef LEAGUE_SOCCER_PITCHSAMPLING_HPP
#define LEAGUE_SOCCER_PITCHSAMPLING_HPP

#include <algorithm>
#include <cmath>

namespace pitchsampling {

// Tile the grass detail; clamp unique pitch markings and noise at their edges.
// Callers supply a non-empty texture and finite coordinates in texel units.
template <typename T>
T BilinearSample(const T* tex, float x, float y, int w, int h, bool repeat = false) {
  if (repeat) {
    x = std::fmod(x, static_cast<float>(w));
    y = std::fmod(y, static_cast<float>(h));
    if (x < 0) {
      x += w;
    }
    if (y < 0) {
      y += h;
    }
  } else {
    x = std::clamp(x, 0.0f, static_cast<float>(w - 1));
    y = std::clamp(y, 0.0f, static_cast<float>(h - 1));
  }
  const int x1 = std::min(static_cast<int>(std::floor(x)), w - 1);
  const int y1 = std::min(static_cast<int>(std::floor(y)), h - 1);
  const int x2 = repeat ? (x1 + 1) % w : std::min(x1 + 1, w - 1);
  const int y2 = repeat ? (y1 + 1) % h : std::min(y1 + 1, h - 1);
  const float fx = x - x1;
  const float fy = y - y1;
  return (tex[y1 * w + x1] * (1.0f - fx) + tex[y1 * w + x2] * fx) * (1.0f - fy) +
         (tex[y2 * w + x1] * (1.0f - fx) + tex[y2 * w + x2] * fx) * fy;
}

}  // namespace pitchsampling
#endif
