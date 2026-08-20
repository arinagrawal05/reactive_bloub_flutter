import 'dart:math' as math;

const double tau = math.pi * 2;

double clamp(double v, [double lo = 0.0, double hi = 1.0]) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

double lerp(double a, double b, double t) {
  return a + (b - a) * t;
}

typedef Easing = double Function(double t);

class Easings {
  static double easeOutCubic(double t) {
    return 1.0 - math.pow(1.0 - t, 3).toDouble();
  }

  static double easeInOutCubic(double t) {
    if (t < 0.5) {
      return 4.0 * math.pow(t, 3).toDouble();
    } else {
      return 1.0 - math.pow(-2.0 * t + 2.0, 3).toDouble() / 2.0;
    }
  }

  static double easeOutQuint(double t) {
    return 1.0 - math.pow(1.0 - t, 5).toDouble();
  }
}

/// 1D periodic noise: seamless loop over `period`, useful for gaze drift.
double loopNoise(double t, double period, [double seed = 0.0]) {
  final double p = (t / period) * tau;
  return 0.55 * math.sin(p + seed) +
      0.3 * math.sin(2.0 * p + seed * 1.7 + 1.1) +
      0.15 * math.sin(3.0 * p + seed * 2.3 + 2.4);
}

/// Deterministic PRNG (mulberry32): same sequence on every read.
double Function() createRng(int seed) {
  int a = seed;
  return () {
    a = (a + 0x6d2b79f5) & 0xFFFFFFFF;
    int t = (a ^ (a >> 15)) & 0xFFFFFFFF;
    t = (t * (t | 1)) & 0xFFFFFFFF;
    t = ((t + (t ^ (t >> 7)) * (61 | t)) ^ t) & 0xFFFFFFFF;
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0;
  };
}

/// Short rounding: useful for keeping path generation clean.
double r2(double v) {
  return (v * 100.0).roundToDouble() / 100.0;
}
