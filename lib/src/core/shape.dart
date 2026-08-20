import 'dart:math' as math;
import 'math.dart';
import 'profiles.dart'; // We will create this next

class MutablePoint {
  double x;
  double y;
  MutablePoint({this.x = 0.0, this.y = 0.0});
}

/// A silhouette = a radial profile r(theta) plus a pose.
class Silhouette {
  final List<double> radii;
  double rot;
  double cx;
  double cy;
  double sx;
  double sy;

  Silhouette({
    required this.radii,
    this.rot = 0.0,
    this.cx = 0.0,
    this.cy = 0.0,
    this.sx = 1.0,
    this.sy = 1.0,
  });

  Silhouette clone() {
    return Silhouette(
      radii: List<double>.from(radii),
      rot: rot,
      cx: cx,
      cy: cy,
      sx: sx,
      sy: sy,
    );
  }
}

final List<double> angles = List.generate(
    profileSamples, (i) => (i / profileSamples) * tau,
    growable: false);
final List<double> cosVals = angles.map(math.cos).toList(growable: false);
final List<double> sinVals = angles.map(math.sin).toList(growable: false);

Silhouette createSilhouette(ProfileName name,
    {double rot = 0.0,
    double cx = 0.0,
    double cy = 0.0,
    double sx = 1.0,
    double sy = 1.0}) {
  return Silhouette(
    radii: List<double>.from(profiles[name]!),
    rot: rot,
    cx: cx,
    cy: cy,
    sx: sx,
    sy: sy,
  );
}

/// Perfect circle: serves as a neutral base.
Silhouette createCircle(double radius,
    {double rot = 0.0,
    double cx = 0.0,
    double cy = 0.0,
    double sx = 1.0,
    double sy = 1.0}) {
  return Silhouette(
    radii: List<double>.filled(profileSamples, radius),
    rot: rot,
    cx: cx,
    cy: cy,
    sx: sx,
    sy: sy,
  );
}

/// Interpolation between two silhouettes. `out` is reused to avoid allocations.
Silhouette blend(Silhouette a, Silhouette b, double t, [Silhouette? out]) {
  final dst = out ??
      Silhouette(radii: List<double>.filled(profileSamples, 0.0));
  for (int i = 0; i < profileSamples; i++) {
    dst.radii[i] = lerp(a.radii[i], b.radii[i], t);
  }
  // Shortest path rotation
  double dRot = b.rot - a.rot;
  while (dRot > math.pi) {
    dRot -= tau;
  }
  while (dRot < -math.pi) {
    dRot += tau;
  }
  dst.rot = a.rot + dRot * t;
  dst.cx = lerp(a.cx, b.cx, t);
  dst.cy = lerp(a.cy, b.cy, t);
  dst.sx = lerp(a.sx, b.sx, t);
  dst.sy = lerp(a.sy, b.sy, t);
  return dst;
}

/// Projects silhouette to screen points. `scale` = ball radius in viewBox units.
List<MutablePoint> toPoints(Silhouette s, double scale,
    [List<MutablePoint>? out]) {
  final points = out ?? [];
  if (points.length != profileSamples) {
    points.clear();
    for (int i = 0; i < profileSamples; i++) {
      points.add(MutablePoint());
    }
  }
  final cr = math.cos(s.rot);
  final sr = math.sin(s.rot);
  for (int i = 0; i < profileSamples; i++) {
    final double r = s.radii[i];
    final double x = r * cosVals[i];
    final double y = r * sinVals[i];
    // rotate then squash then translate
    final double rx = x * cr - y * sr;
    final double ry = x * sr + y * cr;
    final p = points[i];
    p.x = (rx * s.sx + s.cx) * scale;
    p.y = (ry * s.sy + s.cy) * scale;
  }
  return points;
}

/// Closed path -> Catmull-Rom cubics SVG path.
String closedPath(List<MutablePoint> pts, [double tension = 1.0 / 6.0]) {
  final n = pts.length;
  if (n < 3) return '';
  final first = pts[0];
  String d = 'M${r2(first.x)} ${r2(first.y)}';
  for (int i = 0; i < n; i++) {
    final p0 = pts[(i - 1 + n) % n];
    final p1 = pts[i];
    final p2 = pts[(i + 1) % n];
    final p3 = pts[(i + 2) % n];
    final c1x = p1.x + (p2.x - p0.x) * tension;
    final c1y = p1.y + (p2.y - p0.y) * tension;
    final c2x = p2.x - (p3.x - p1.x) * tension;
    final c2y = p2.y - (p3.y - p1.y) * tension;
    d += 'C${r2(c1x)} ${r2(c1y)} ${r2(c2x)} ${r2(c2y)} ${r2(p2.x)} ${r2(p2.y)}';
  }
  return '$d Z';
}

/// Arbitrary polygon -> radial profile by raycasting from `cx, cy`.
List<double> profileFromPolygon(List<MutablePoint> poly, double cx, double cy) {
  final radii = List<double>.filled(profileSamples, 0.0);
  final n = poly.length;
  for (int k = 0; k < profileSamples; k++) {
    final dx = cosVals[k];
    final dy = sinVals[k];
    double best = 0.0;
    for (int i = 0; i < n; i++) {
      final a = poly[i];
      final b = poly[(i + 1) % n];
      final ex = b.x - a.x;
      final ey = b.y - a.y;
      final den = dx * ey - dy * ex;
      if (den.abs() < 1e-9) continue;
      final px = a.x - cx;
      final py = a.y - cy;
      final t = (px * ey - py * ex) / den; // distance along ray
      final u = (px * dy - py * dx) / den; // position on segment
      if (t > best && u >= 0 && u <= 1) best = t;
    }
    radii[k] = best;
  }
  return radii;
}

/// Convex hull of two circles.
List<MutablePoint> hullOfCircles(double x1, double y1, double r1, double x2,
    double y2, double r2v, [int steps = 96]) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final dist = math.max(math.sqrt(dx * dx + dy * dy), 1e-6);
  final base = math.atan2(dy, dx);
  final spread = math.acos(clamp((r1 - r2v) / dist, -1.0, 1.0));
  final List<MutablePoint> pts = [];
  
  // arc of large circle
  for (int i = 0; i <= steps ~/ 2; i++) {
    final a = base + spread + ((tau - 2 * spread) * i) / (steps / 2);
    pts.add(MutablePoint(x: x1 + math.cos(a) * r1, y: y1 + math.sin(a) * r1));
  }
  // arc of small circle
  for (int i = 0; i <= steps ~/ 2; i++) {
    final a = base - spread + ((2 * spread) * i) / (steps / 2);
    pts.add(MutablePoint(x: x2 + math.cos(a) * r2v, y: y2 + math.sin(a) * r2v));
  }
  return pts;
}

/// Radius of profile in arbitrary direction, by interpolating neighboring samples.
double radiusAtAngle(List<double> radii, double angle) {
  final n = radii.length;
  final t = ((((angle / tau) % 1) + 1) % 1) * n;
  final i = t.floor();
  return lerp(radii[i % n], radii[(i + 1) % n], t - i);
}

/// Superellipse profile
List<double> superellipseProfile(double n, [double sx = 1.0, double sy = 1.0]) {
  return List.generate(profileSamples, (i) {
    final c = math.pow((cosVals[i] / sx).abs(), n);
    final s = math.pow((sinVals[i] / sy).abs(), n);
    return math.pow(c + s, -1.0 / n).toDouble();
  });
}

class CircleDef {
  double x;
  double y;
  double r;
  CircleDef({required this.x, required this.y, required this.r});
}

/// Union of circles profile
List<double> unionOfCirclesProfile(List<CircleDef> circles) {
  final out = List<double>.filled(profileSamples, 0.0);
  for (int i = 0; i < profileSamples; i++) {
    final dx = cosVals[i];
    final dy = sinVals[i];
    double best = 0.0;
    for (final c in circles) {
      final b = dx * c.x + dy * c.y;
      final disc = b * b - (c.x * c.x + c.y * c.y - c.r * c.r);
      if (disc < 0) continue;
      final t = b + math.sqrt(disc);
      if (t > best) best = t;
    }
    out[i] = best;
  }
  return out;
}

/// Polygon with rounded corners via Minkowski sum
List<MutablePoint> roundedPolygon(List<MutablePoint> verts, double rc,
    [int arcSteps = 10]) {
  final n = verts.length;
  final List<MutablePoint> out = [];
  double normal(MutablePoint a, MutablePoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final len = math.max(math.sqrt(dx * dx + dy * dy), 1.0);
    return math.atan2(-dx / len, dy / len);
  }

  for (int i = 0; i < n; i++) {
    final prev = verts[(i - 1 + n) % n];
    final cur = verts[i];
    final next = verts[(i + 1) % n];
    final a0 = normal(prev, cur);
    final a1 = normal(cur, next);
    double d = a1 - a0;
    while (d > math.pi) {
      d -= tau;
    }
    while (d < -math.pi) {
      d += tau;
    }
    for (int k = 0; k <= arcSteps; k++) {
      final a = a0 + (d * k) / arcSteps;
      out.add(MutablePoint(
          x: cur.x + math.cos(a) * rc, y: cur.y + math.sin(a) * rc));
    }
  }
  return out;
}

/// Regular rounded polygon profile
List<double> regularPolygonProfile(int sides, double radius, double rc,
    [double rotationDeg = 0.0]) {
  final rot = (rotationDeg * math.pi) / 180.0;
  final verts = List.generate(sides, (i) {
    final a = rot + (i / sides) * tau;
    return MutablePoint(
        x: math.cos(a) * (radius - rc), y: math.sin(a) * (radius - rc));
  });
  return profileFromPolygon(roundedPolygon(verts, rc), 0.0, 0.0);
}

/// Exact closed poly path
String polyPath(List<MutablePoint> pts, [double scale = 1.0]) {
  if (pts.length < 3) return '';
  String d = '';
  for (int i = 0; i < pts.length; i++) {
    final p = pts[i];
    d += '${i == 0 ? 'M' : 'L'}${r2(p.x * scale)} ${r2(p.y * scale)}';
  }
  return '$d Z';
}

/// Capsule path (centered on origin)
String capsulePath(double w, double h) {
  final hw = math.max(w, 0.01) / 2.0;
  final hh = math.max(h, 0.01) / 2.0;
  final r = math.min(hw, hh);
  return 'M${r2(-hw)} ${r2(-hh + r)}'
      'A${r2(r)} ${r2(r)} 0 0 1 ${r2(-hw + r)} ${r2(-hh)}'
      'L${r2(hw - r)} ${r2(-hh)}'
      'A${r2(r)} ${r2(r)} 0 0 1 ${r2(hw)} ${r2(-hh + r)}'
      'L${r2(hw)} ${r2(hh - r)}'
      'A${r2(r)} ${r2(r)} 0 0 1 ${r2(hw - r)} ${r2(hh)}'
      'L${r2(-hw + r)} ${r2(hh)}'
      'A${r2(r)} ${r2(r)} 0 0 1 ${r2(-hw)} ${r2(hh - r)}Z';
}

/// Smooth a radial profile (low-pass filter) to eliminate sharp corners
List<double> smoothProfile(List<double> radii, [int passes = 1]) {
  List<double> out = List<double>.from(radii);
  final n = radii.length;
  for (int p = 0; p < passes; p++) {
    final next = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final l = out[(i - 1 + n) % n];
      final c = out[i];
      final r = out[(i + 1) % n];
      next[i] = l * 0.25 + c * 0.5 + r * 0.25;
    }
    out = next;
  }
  return out;
}
