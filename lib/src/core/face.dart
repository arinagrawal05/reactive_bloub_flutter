import 'dart:math' as math;
import 'math.dart';

class Vec3 {
  final double x;
  final double y;
  final double z;
  const Vec3(this.x, this.y, this.z);
}

const double eyeSplit = 15.46;
const double eyeW = 0.186;
const double eyeH = 0.412;

class HeadGaze {
  final double yaw;
  final double pitch;
  final double roll;

  const HeadGaze({this.yaw = 0.0, this.pitch = 0.0, this.roll = 0.0});
}

const HeadGaze restGaze = HeadGaze(yaw: 28.49, pitch: 28.62, roll: -13.0);

class EyePose {
  final double x;
  final double y;
  final double a;
  final double b;
  final double c;
  final double d;
  final double depth;

  const EyePose({
    required this.x,
    required this.y,
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.depth,
  });
}

double _deg(double d) => (d * math.pi) / 180.0;

List<Vec3> _spin(Vec3 u, Vec3 v, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  return [
    Vec3(u.x * c + v.x * s, u.y * c + v.y * s, u.z * c + v.z * s),
    Vec3(v.x * c - u.x * s, v.y * c - u.y * s, v.z * c - u.z * s),
  ];
}

List<EyePose> eyePoses(HeadGaze gaze, double scale,
    [double split = eyeSplit]) {
  Vec3 f = const Vec3(0, 0, 1);
  Vec3 right = const Vec3(1, 0, 0);
  Vec3 down = const Vec3(0, 1, 0);

  // yaw
  var res = _spin(f, right, _deg(gaze.yaw));
  f = res[0];
  right = res[1];

  // pitch
  res = _spin(down, f, _deg(gaze.pitch));
  down = res[0];
  f = res[1];

  // roll
  res = _spin(right, down, _deg(gaze.roll));
  right = res[0];
  down = res[1];

  EyePose build(double side) {
    final efEr = _spin(f, right, _deg(split * side));
    final ef = efEr[0];
    final er = efEr[1];
    return EyePose(
      x: ef.x * scale,
      y: ef.y * scale,
      a: er.x,
      b: er.y,
      c: down.x,
      d: down.y,
      depth: ef.z,
    );
  }

  return [build(-1.0), build(1.0)];
}

class Liveliness {
  final double dYaw;
  final double dPitch;
  final double dRoll;
  final double lid;
  final double driftX;
  final double driftY;
  final double breath;

  const Liveliness({
    required this.dYaw,
    required this.dPitch,
    required this.dRoll,
    required this.lid,
    required this.driftX,
    required this.driftY,
    required this.breath,
  });
}

final _blinkRng = createRng(0x5eed);
final List<double> _blinks = () {
  final List<double> out = [];
  double t = 1.4;
  while (t < 900) {
    out.add(t);
    t += 1.9 + _blinkRng() * 2.7;
    if (_blinkRng() < 0.18) {
      out.add(t);
      t += 0.24;
    }
  }
  return out;
}();

const double blinkDur = 0.18;

double blinkLid(double t) {
  for (int i = 0; i < _blinks.length; i++) {
    final start = _blinks[i];
    if (t < start) break;
    final k = (t - start) / blinkDur;
    if (k >= 0 && k <= 1) {
      return k < 0.45 ? 1.0 - k / 0.45 : (k - 0.45) / 0.55;
    }
  }
  return 1.0;
}

Liveliness getLiveliness(double t,
    {double wander = 1.0, bool blink = true, bool float = true}) {
  return Liveliness(
    dYaw: (loopNoise(t, 11.3, 0.4) * 5.5 + loopNoise(t, 3.7, 2.1) * 1.6) *
        wander,
    dPitch: (loopNoise(t, 9.1, 1.3) * 4.2 + loopNoise(t, 4.3, 0.7) * 1.3) *
        wander,
    dRoll: loopNoise(t, 13.7, 3.2) * 2.2 * wander,
    lid: blink ? blinkLid(t) : 1.0,
    driftX: float ? loopNoise(t, 7.9, 1.9) * 0.006 : 0.0,
    driftY: float ? loopNoise(t, 5.3, 0.3) * 0.007 : 0.0,
    breath: float ? 1.0 + math.sin((t / 3.4) * math.pi * 2.0) * 0.005 : 1.0,
  );
}

double getBlinkScale(double lid) {
  return 0.06 + 0.94 * clamp(lid);
}
