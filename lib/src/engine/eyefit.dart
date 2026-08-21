import '../core/face.dart';
import '../core/shape.dart';
import '../ui/bloub_enums.dart';
import 'skins.dart';
import 'mascot_expression.dart';
import 'mascot_state.dart';
import 'dart:math' as math;

const double _r = 100.0;
const double _deriveYaw = 5.5 + 1.6;
const double _derivePitch = 4.2 + 1.3;
const double _deriveX = 0.006;
const double _deriveY = 0.007;

class Visage {
  final HeadGaze gaze;
  final double split;
  final List<EyeCfg> eyes;
  Visage(this.gaze, this.split, this.eyes);
}

class Empreinte {
  final double x;
  final double y;
  final double ax;
  final double ay;
  final double r;
  final List<double> m;
  Empreinte(this.x, this.y, this.ax, this.ay, this.r, this.m);
}

List<Empreinte> _empreintes(Visage visage, Silhouette sil, List<double> radii) {
  final List<Empreinte> out = [];
  final poses = eyePoses(visage.gaze, _r, visage.split);
  for (int i = 0; i < 2; i++) {
    final e = poses[i];
    if (e.depth <= 0.02) continue;
    final cfg = visage.eyes[i];
    final phi = (cfg.tilt * math.pi) / 180.0;
    final cp = math.cos(phi);
    final sp = math.sin(phi);
    final ax = e.a * cp + e.c * sp;
    final ay = e.b * cp + e.d * sp;
    final cx = -e.a * sp + e.c * cp;
    final cy = -e.b * sp + e.d * cp;

    final hw = math.max(cfg.w * _r, 0.01) / 2.0;
    final hh = math.max(cfg.h * _r, 0.01) / 2.0;
    final r = math.min(hw, hh);
    final long = hh > hw;
    final demi = long ? hh - r : hw - r;
    final fit = radiusAtAngle(radii, math.atan2(e.y, e.x) - sil.rot);
    out.add(
      Empreinte(
        e.x * fit,
        e.y * fit,
        (long ? cx : ax) * demi,
        (long ? cy : ay) * demi,
        r,
        [ax, ay, cx, cy],
      ),
    );
  }
  return out;
}

class ApprocheResult {
  final double d;
  final double ux;
  final double uy;
  ApprocheResult(this.d, this.ux, this.uy);
}

ApprocheResult _approche(
  List<MutablePoint> pts,
  double x0,
  double y0,
  double x1,
  double y1,
) {
  final sx = x1 - x0;
  final sy = y1 - y0;
  final len2 = sx * sx + sy * sy;
  double best = double.infinity;
  double vx = 0;
  double vy = 0;
  for (int i = 0; i < pts.length; i++) {
    final p = pts[i];
    double t = len2 > 0 ? ((p.x - x0) * sx + (p.y - y0) * sy) / len2 : 0;
    t = t < 0
        ? 0
        : t > 1
        ? 1
        : t;
    final ex = x0 + t * sx - p.x;
    final ey = y0 + t * sy - p.y;
    final d2 = ex * ex + ey * ey;
    if (d2 < best) {
      best = d2;
      vx = ex;
      vy = ey;
    }
  }
  final d = math.sqrt(best);
  return ApprocheResult(d, d > 1e-9 ? vx / d : 0, d > 1e-9 ? vy / d : 0);
}

class Epreuve {
  final List<Empreinte> empreintes;
  final List<Empreinte> reference;
  final List<MutablePoint> contour;
  final List<MutablePoint> calContour;
  Epreuve(this.empreintes, this.reference, this.contour, this.calContour);
}

final double _flottement =
    math.sqrt(_deriveX * _deriveX + _deriveY * _deriveY) * _r;

class PireResult {
  final double marge;
  final double ux;
  final double uy;
  PireResult(this.marge, this.ux, this.uy);
}

PireResult _pire(
  List<MutablePoint> pts,
  List<Empreinte> emps,
  double tx,
  double ty,
) {
  double marge = double.infinity;
  double ux = 0;
  double uy = 0;
  for (final e in emps) {
    final x = e.x + tx;
    final y = e.y + ty;
    final a = _approche(pts, x - e.ax, y - e.ay, x + e.ax, y + e.ay);
    final m0 = e.m[0];
    final m1 = e.m[1];
    final m2 = e.m[2];
    final m3 = e.m[3];
    final rayon =
        e.r *
            math.sqrt(
              math.pow(m0 * a.ux + m1 * a.uy, 2) +
                  math.pow(m2 * a.ux + m3 * a.uy, 2),
            ) +
        _flottement;
    if (a.d - rayon < marge) {
      marge = a.d - rayon;
      ux = a.ux;
      uy = a.uy;
    }
  }
  return PireResult(marge, ux, uy);
}

const int _directions = 12;
const int _dichotomie = 8;

class Vec2 {
  final double x;
  final double y;
  const Vec2(this.x, this.y);
}

Vec2 _resous(List<Epreuve> epreuves) {
  if (epreuves.isEmpty) return const Vec2(0, 0);

  double margeFn(double tx, double ty) {
    double m = double.infinity;
    for (final ep in epreuves) {
      m = math.min(m, _pire(ep.contour, ep.empreintes, tx, ty).marge);
    }
    return m;
  }

  double requis = double.infinity;
  for (final ep in epreuves) {
    requis = math.min(requis, _pire(ep.calContour, ep.reference, 0, 0).marge);
  }

  double mx = 0;
  double my = 0;
  final emps = epreuves[0].empreintes;
  for (final e in emps) {
    mx -= e.x / emps.length;
    my -= e.y / emps.length;
  }
  final course = math.max(0.35 * _r, math.sqrt(mx * mx + my * my) * 1.25);
  requis = math.min(requis, margeFn(mx, my));

  final depart = margeFn(0, 0);
  if (depart >= requis && depart >= 0) return const Vec2(0, 0);
  final cible = math.max(requis, 0.0);

  double meilleurX = 0;
  double meilleurY = 0;
  double meilleureNorme = double.infinity;
  double secoursX = 0;
  double secoursY = 0;
  double secours = depart;

  for (int d = 0; d < _directions; d++) {
    final a = (d / _directions) * math.pi * 2;
    final ux = math.cos(a);
    final uy = math.sin(a);
    if (margeFn(ux * course, uy * course) < cible) {
      for (final k in [0.3, 0.6, 1.0]) {
        final m = margeFn(ux * course * k, uy * course * k);
        if (m > secours) {
          secours = m;
          secoursX = ux * course * k;
          secoursY = uy * course * k;
        }
      }
      continue;
    }
    double bas = 0;
    double haut = course;
    for (int i = 0; i < _dichotomie; i++) {
      final mid = (bas + haut) / 2;
      if (margeFn(ux * mid, uy * mid) >= cible) {
        haut = mid;
      } else {
        bas = mid;
      }
    }
    if (haut < meilleureNorme) {
      meilleureNorme = haut;
      meilleurX = ux * haut;
      meilleurY = uy * haut;
    }
  }

  final x = meilleureNorme == double.infinity ? secoursX : meilleurX;
  final y = meilleureNorme == double.infinity ? secoursY : meilleurY;
  return Vec2(
    double.parse((x / _r).toStringAsFixed(6)),
    double.parse((y / _r).toStringAsFixed(6)),
  );
}

Visage _visageDe(StateDef def, Pose pose, BotExpression? expr) {
  if (def.baseFace && expr != null) {
    return Visage(expr.gaze, expr.split, expr.eyes);
  }
  return Visage(pose.gaze, pose.split, pose.eyes);
}

List<double> _dates(StateDef def) {
  String signature(Pose p) {
    return '${p.gaze.yaw}|${p.gaze.pitch}|${p.gaze.roll}|${p.split}|'
        '${p.eyes[0].w}|${p.eyes[0].h}|${p.eyes[0].tilt}|${p.eyes[0].open}|'
        '${p.eyes[1].w}|${p.eyes[1].h}|${p.eyes[1].tilt}|${p.eyes[1].open}|'
        '${p.sil.rot}|${p.sil.cx}|${p.sil.cy}|${p.sil.sx}|${p.sil.sy}';
  }

  if (signature(def.pose(0, null)) == signature(def.pose(def.duration, null))) {
    return [0.0];
  }
  const n = 3;
  return List.generate(n, (i) => (i / (n - 1)) * def.duration);
}

Vec2 _decalagePour(StateDef def, List<double> radii, BotExpression? expr) {
  final List<Epreuve> epreuves = [];
  for (final t in _dates(def)) {
    final pose = def.pose(t, radii);
    final contour = toPoints(
      Silhouette(
        radii: radii,
        rot: pose.sil.rot,
        cx: pose.sil.cx,
        cy: pose.sil.cy,
        sx: pose.sil.sx,
        sy: pose.sil.sy,
      ),
      _r,
    );
    final calContour = toPoints(pose.sil, _r);
    final v = _visageDe(def, pose, expr);
    final List<Visage> coins = [];
    for (final dy in [-_deriveYaw, _deriveYaw]) {
      for (final dp in [-_derivePitch, _derivePitch]) {
        coins.add(
          Visage(
            HeadGaze(
              yaw: v.gaze.yaw + dy,
              pitch: v.gaze.pitch + dp,
              roll: v.gaze.roll,
            ),
            v.split,
            v.eyes,
          ),
        );
      }
    }
    for (final c in coins) {
      epreuves.add(
        Epreuve(
          _empreintes(c, pose.sil, radii),
          _empreintes(c, pose.sil, pose.sil.radii),
          contour,
          calContour,
        ),
      );
    }
  }
  return _resous(epreuves);
}

const Vec2 _nul = Vec2(0, 0);

String _clef(BloubState state, BloubExpression? expr) => '${state.name}|${expr?.name ?? ''}';

Map<List<double>, Map<String, Vec2>>? _decalagesCache;

Map<List<double>, Map<String, Vec2>> _batir() {
  final Map<List<double>, Map<String, Vec2>> result = {};
  for (final forme in shapes) {
    final Map<String, Vec2> par = {};
    for (final def in states) {
      if (!def.baseBody) continue;
      final List<BotExpression?> exprs = def.baseFace
          ? [null, ...expressions]
          : [null];
      for (final expr in exprs) {
        par[_clef(def.id, expr?.id)] = _decalagePour(def, forme.radii, expr);
      }
    }
    result[forme.radii] = par;
  }
  return result;
}

Vec2 decalageDesYeux(List<double>? radii, BloubState state, BloubExpression? expr) {
  if (radii == null) return _nul;
  _decalagesCache ??= _batir();
  final par = _decalagesCache![radii];
  if (par == null) return _nul;
  return par[_clef(state, expr)] ?? par[_clef(state, null)] ?? _nul;
}
