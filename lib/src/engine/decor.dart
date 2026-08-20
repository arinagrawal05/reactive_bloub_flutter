import 'dart:math' as math;
import '../core/math.dart';

String wheel(double hue, [double s = 0.55, double l = 0.62]) {
  final h = ((hue % 360) + 360) % 360;
  final c = (1.0 - (2.0 * l - 1.0).abs()) * s;
  final x = c * (1.0 - (((h / 60.0) % 2.0) - 1.0).abs());
  final m = l - c / 2.0;

  double r, g, b;
  if (h < 60) {
    r = c; g = x; b = 0.0;
  } else if (h < 120) {
    r = x; g = c; b = 0.0;
  } else if (h < 180) {
    r = 0.0; g = c; b = x;
  } else if (h < 240) {
    r = 0.0; g = x; b = c;
  } else if (h < 300) {
    r = x; g = 0.0; b = c;
  } else {
    r = c; g = 0.0; b = x;
  }

  String hex(double v) {
    return ((v + m) * 255).round().toRadixString(16).padLeft(2, '0');
  }

  return '#${hex(r)}${hex(g)}${hex(b)}';
}

class DotRender {
  final double x;
  final double y;
  final double r;
  final double opacity;
  final String? color;
  final double? depth;
  final String? d;
  final double? rot;

  const DotRender({
    required this.x,
    required this.y,
    required this.r,
    required this.opacity,
    this.color,
    this.depth,
    this.d,
    this.rot,
  });
}

class ArcSeed {
  final double a;
  final double k;
  final double tilt;
  final double speed;
  final double phase;
  final double sweep;
  final double hue;
  final double hueSpan;
  final double width;
  final double cx;
  final double cy;

  const ArcSeed({
    required this.a,
    required this.k,
    required this.tilt,
    required this.speed,
    required this.phase,
    required this.sweep,
    required this.hue,
    required this.hueSpan,
    required this.width,
    required this.cx,
    required this.cy,
  });
}

class ArcSpec {
  final String id;
  final ArcSeed seed;
  final double t;
  final double opacity;

  const ArcSpec({
    required this.id,
    required this.seed,
    required this.t,
    required this.opacity,
  });
}

class ArcRender {
  final String id;
  final String front;
  final String back;
  final double width;
  final double opacity;
  final ArcGrad grad;

  const ArcRender({
    required this.id,
    required this.front,
    required this.back,
    required this.width,
    required this.opacity,
    required this.grad,
  });
}

class ArcGrad {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final List<String> stops;

  const ArcGrad({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.stops,
  });
}

ArcRender arcRender(ArcSeed seed, double t, double scale, String id,
    [double opacity = 1.0]) {
  final spin = seed.phase + t * seed.speed * math.pi * 2.0;
  final cu = math.cos(seed.tilt);
  final su = math.sin(seed.tilt);
  final kz = math.sqrt(math.max(0.0, 1.0 - seed.k * seed.k));

  const n = 64;
  final span = seed.sweep * math.pi * 2.0;
  String front = '';
  String backStr = '';
  bool? prev;

  for (int i = 0; i <= n; i++) {
    final th = spin + (i / n) * span;
    final ct = math.cos(th);
    final st = math.sin(th);
    final x = seed.a * (ct * cu + st * -su * seed.k) + seed.cx;
    final y = seed.a * (ct * su + st * cu * seed.k) + seed.cy;
    final z = seed.a * st * kz;

    final behind = z < 0;
    final sx = r2(x * scale);
    final sy = r2(y * scale);
    final cmd = behind != prev ? 'M' : 'L';
    if (behind) {
      backStr += '$cmd$sx $sy';
    } else {
      front += '$cmd$sx $sy';
    }
    prev = behind;
  }

  final gx = math.cos(seed.tilt) * seed.a * scale;
  final gy = math.sin(seed.tilt) * seed.a * scale;
  return ArcRender(
    id: id,
    front: front,
    back: backStr,
    width: seed.width * scale,
    opacity: opacity,
    grad: ArcGrad(
      x1: r2(seed.cx * scale - gx),
      y1: r2(seed.cy * scale - gy),
      x2: r2(seed.cx * scale + gx),
      y2: r2(seed.cy * scale + gy),
      stops: [
        wheel(seed.hue),
        wheel(seed.hue + seed.hueSpan * 0.5),
        wheel(seed.hue + seed.hueSpan)
      ],
    ),
  );
}

final _ringRng = createRng(0xa11ce);
final List<ArcSeed> rings = List.generate(6, (i) {
  return ArcSeed(
    a: 1.3 + _ringRng() * 0.1,
    k: 0.05 + _ringRng() * 0.4,
    tilt: (i / 6.0) * math.pi + _ringRng() * 0.5,
    speed: 3.0 + _ringRng() * 0.7,
    phase: _ringRng() * math.pi * 2.0,
    sweep: 0.6 + _ringRng() * 0.25,
    hue: (i * 360.0) / 6.0 + _ringRng() * 30.0,
    hueSpan: 60.0 + _ringRng() * 60.0,
    width: 0.05 + _ringRng() * 0.012,
    cx: 0,
    cy: 0.1,
  );
});

final List<ArcSeed> swoosh = List.generate(4, (i) {
  return ArcSeed(
    a: 0.78 + i * 0.2,
    k: 0.05 + i * 0.02,
    tilt: -0.62 + i * 0.05,
    speed: 0.3,
    phase: 0.06 * i,
    sweep: 0.4,
    hue: 95.0 + i * 62.0,
    hueSpan: 100.0,
    width: 0.05,
    cx: 0.0,
    cy: -0.12,
  );
});

const List<double> dotX = [-0.557, -0.013, 0.532];
const double dotR = 0.165;
const double dotPeak = 1.25;

final _pRng = createRng(0xbeef);

class ParticleSpec {
  final double birth;
  final double angle;
  final double rho;
  ParticleSpec(this.birth, this.angle, this.rho);
}

final List<ParticleSpec> _particlesSpec = List.generate(5, (i) {
  return ParticleSpec(i * 0.2, _pRng() * math.pi * 2.0, 0.58 + _pRng() * 0.18);
});

List<DotRender> getParticles(double t, double scale) {
  final List<DotRender> out = [];
  for (final p in _particlesSpec) {
    final u = t - p.birth;
    if (u < 0 || u > 0.62) continue;
    final rho = p.rho * math.pow(0.75, u * 10);
    final a = p.angle + (u * 100.0 * math.pi) / 180.0;
    out.add(DotRender(
      x: math.cos(a) * rho * scale,
      y: math.sin(a) * rho * scale,
      r: (0.04 + 0.028 * clamp(u / 0.55)) * scale,
      depth: clamp(1.0 - rho / 0.8),
      opacity: clamp(u / 0.06) * clamp((0.62 - u) / 0.08),
    ));
  }
  return out;
}

final _cometRng = createRng(0xc0e7);
final List<ArcSeed> cometRibbons = List.generate(4, (i) {
  final d = i - 1.5;
  return ArcSeed(
    a: 0.85 * (1.0 + d * 0.03),
    k: (0.15 / 0.85) * (1.0 + d * 0.16),
    tilt: (34.0 * math.pi) / 180.0 + d * 0.035,
    speed: 210.0 / 360.0,
    phase: -i * 0.045 + _cometRng() * 0.012,
    sweep: 0.34,
    hue: i * 85.0 + _cometRng() * 20.0,
    hueSpan: 80.0,
    width: 0.095,
    cx: 0.0,
    cy: 0.0,
  );
});

const double cometDot = 0.129;
const String notifBlue = '#2496e8';
const double notifAngle = -42;
const double notifDist = 1.003;
const double notifR = 0.15;
const double notifPop = 1.14;
const double notifMargin = 0.054;
