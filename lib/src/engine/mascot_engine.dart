import 'dart:math' as math;
import '../core/face.dart';
import '../core/math.dart';
import '../core/shape.dart';
import '../ui/bloub_enums.dart';
import 'decor.dart';
import 'eyefit.dart';
import 'mascot_expression.dart';
import 'mascot_state.dart';

class RenderedEye {
  final String d;
  final String matrix;
  final double alpha;

  const RenderedEye({
    required this.d,
    required this.matrix,
    required this.alpha,
  });
}

class BotFrame {
  final String bodyPath;
  final double bodyAlpha;
  final List<RenderedEye> eyes;
  final List<DotRender> dots;
  final bool dotsBehind;
  final List<ArcRender> arcs;
  final NotifRender? notif;
  final NotifRender? notch;

  const BotFrame({
    required this.bodyPath,
    required this.bodyAlpha,
    required this.eyes,
    required this.dots,
    required this.dotsBehind,
    required this.arcs,
    this.notif,
    this.notch,
  });
}

class Look {
  final double yaw;
  final double pitch;
  final double mix;
  final double spin;
  final double wander;

  const Look({
    required this.yaw,
    required this.pitch,
    required this.mix,
    required this.spin,
    required this.wander,
  });
}

const Look noLook = Look(yaw: 0, pitch: 0, mix: 0, spin: 0, wander: 1);

Look _lerpLook(Look a, Look b, double t) {
  return Look(
    yaw: lerp(a.yaw, b.yaw, t),
    pitch: lerp(a.pitch, b.pitch, t),
    mix: lerp(a.mix, b.mix, t),
    spin: lerp(a.spin, b.spin, t),
    wander: lerp(a.wander, b.wander, t),
  );
}

EyeCfg _lerpEye(EyeCfg a, EyeCfg b, double t) {
  return EyeCfg(
    w: lerp(a.w, b.w, t),
    h: lerp(a.h, b.h, t),
    open: lerp(a.open, b.open, t),
    tilt: lerp(a.tilt, b.tilt, t),
  );
}

Pose blendPose(Pose a, Pose b, double t) {
  final out = 1.0 - t;

  final List<DotRender> blendedDots = [];
  for (final d in a.dots) {
    blendedDots.add(
      DotRender(
        x: d.x,
        y: d.y,
        r: d.r,
        opacity: d.opacity * out,
        color: d.color,
        depth: d.depth,
        d: d.d,
        rot: d.rot,
      ),
    );
  }
  for (final d in b.dots) {
    blendedDots.add(
      DotRender(
        x: d.x,
        y: d.y,
        r: d.r,
        opacity: d.opacity * t,
        color: d.color,
        depth: d.depth,
        d: d.d,
        rot: d.rot,
      ),
    );
  }

  final List<ArcSpec> blendedArcs = [];
  for (final r in a.arcs) {
    blendedArcs.add(
      ArcSpec(id: 'a${r.id}', seed: r.seed, t: r.t, opacity: r.opacity * out),
    );
  }
  for (final r in b.arcs) {
    blendedArcs.add(
      ArcSpec(id: 'b${r.id}', seed: r.seed, t: r.t, opacity: r.opacity * t),
    );
  }

  return Pose(
    sil: blend(a.sil, b.sil, t),
    offX: lerp(a.offX, b.offX, t),
    offY: lerp(a.offY, b.offY, t),
    gaze: HeadGaze(
      yaw: lerp(a.gaze.yaw, b.gaze.yaw, t),
      pitch: lerp(a.gaze.pitch, b.gaze.pitch, t),
      roll: lerp(a.gaze.roll, b.gaze.roll, t),
    ),
    split: lerp(a.split, b.split, t),
    eyes: [
      _lerpEye(a.eyes[0], b.eyes[0], t),
      _lerpEye(a.eyes[1], b.eyes[1], t),
    ],
    eyeAlpha: lerp(a.eyeAlpha, b.eyeAlpha, t),
    bodyAlpha: lerp(a.bodyAlpha, b.bodyAlpha, t),
    dots: blendedDots,
    arcs: blendedArcs,
    notif: t < 0.5 ? a.notif : b.notif,
    dotsBehind: t < 0.5 ? a.dotsBehind : b.dotsBehind,
  );
}

class MascotEngine {
  final double scale;

  BloubState _cur;
  BloubState? _prev;
  Pose? _departFige;
  double _tCur = 0;
  double _tPrev = 0;
  double _blinkAt = -10.0;
  final List<MutablePoint> _pts = [];

  List<double>? _shape;
  List<double>? _shapePrev;
  double _shapeAt = -10.0;

  BotExpression? _expr;
  BotExpression? _exprPrev;
  double _exprAt = -10.0;

  Look _look = noLook;
  Look _lookPrev = noLook;
  double _lookAt = -10.0;
  double _lookMorph = 0.24;

  static const double shapeMorph = 0.45;
  static const double lookMorphConst = 0.24;

  MascotEngine({
    this.scale = 100.0,
    BloubState initial = BloubState.idle,
    List<double>? shape,
    BotExpression? expression,
  }) : _cur = initial,
       _shape = shape,
       _expr = expression;

  void setExpression(BotExpression? expression, [double now = 0]) {
    if (expression == _expr) return;
    _exprPrev = _expr;
    _expr = expression;
    _exprAt = now;
  }

  BotExpression? _exprAtTime(double now) {
    final to = _expr;
    final from = _exprPrev;
    if (to == null || from == null) return to;
    final k = (now - _exprAt) / shapeMorph;
    if (k >= 1.0) return to;
    return blendExpression(from, to, Easings.easeOutQuint(clamp(k)));
  }

  void setShape(List<double>? radii, [double now = 0]) {
    if (radii == _shape) return;
    _shapePrev = _shape;
    _shape = radii;
    _shapeAt = now;
  }

  List<double>? _shapeAtTime(double now) {
    final to = _shape;
    final from = _shapePrev;
    if (to == null || from == null) return to;
    final k = (now - _shapeAt) / shapeMorph;
    if (k >= 1.0) return to;
    final t = Easings.easeOutQuint(clamp(k));
    final List<double> res = [];
    for (int i = 0; i < to.length; i++) {
      res.add(lerp(from[i], to[i], t));
    }
    return res;
  }

  void setLook(Look? look, double now, [double morph = lookMorphConst]) {
    if (look != null &&
        (!look.yaw.isFinite ||
            !look.pitch.isFinite ||
            !look.mix.isFinite ||
            !look.spin.isFinite ||
            !look.wander.isFinite)) {
      return;
    }
    _lookPrev = _lookAtTime(now);
    _look = look ?? noLook;
    _lookAt = now;
    _lookMorph = morph;
  }

  Look _lookAtTime(double now) {
    final k = (now - _lookAt) / _lookMorph;
    if (k >= 1.0) return _look;
    return _lerpLook(_lookPrev, _look, Easings.easeOutQuint(clamp(k)));
  }

  Pose _posed(
    StateDef def,
    double t,
    List<double>? shape,
    BotExpression? expr,
  ) {
    var pose = def.pose(t, shape);
    if (def.baseBody && shape != null) {
      pose = basePose(
        sil: Silhouette(
          radii: shape,
          rot: pose.sil.rot,
          cx: pose.sil.cx,
          cy: pose.sil.cy,
          sx: pose.sil.sx,
          sy: pose.sil.sy,
        ),
        offX: pose.offX,
        offY: pose.offY,
        gaze: pose.gaze,
        split: pose.split,
        eyes: pose.eyes,
        eyeAlpha: pose.eyeAlpha,
        bodyAlpha: pose.bodyAlpha,
        dots: pose.dots,
        arcs: pose.arcs,
        notif: pose.notif,
        dotsBehind: pose.dotsBehind,
      );
    }
    if (def.baseFace && expr != null) {
      pose = basePose(
        sil: pose.sil,
        offX: pose.offX,
        offY: pose.offY,
        gaze: expr.gaze,
        split: expr.split,
        eyes: expr.eyes,
        eyeAlpha: pose.eyeAlpha,
        bodyAlpha: pose.bodyAlpha,
        dots: pose.dots,
        arcs: pose.arcs,
        notif: pose.notif,
        dotsBehind: pose.dotsBehind,
      );
    }
    return pose;
  }

  Vec2 _decalageAtTime(double now, BloubState state) {
    Vec2 surAxe(double debut, double duree, Vec2 a, Vec2 b) {
      if (a.x == b.x && a.y == b.y) return b;
      final k = (now - debut) / duree;
      if (k >= 1.0) return b;
      final t = Easings.easeOutQuint(clamp(k));
      return Vec2(lerp(a.x, b.x, t), lerp(a.y, b.y, t));
    }

    Vec2 parForme(List<double>? radii) {
      return surAxe(
        _exprAt,
        shapeMorph,
        decalageDesYeux(radii, state, _exprPrev?.id),
        decalageDesYeux(radii, state, _expr?.id),
      );
    }

    return surAxe(_shapeAt, shapeMorph, parForme(_shapePrev), parForme(_shape));
  }

  BloubState get state => _cur;

  void reset(BloubState id, double now) {
    _cur = id;
    _prev = null;
    _departFige = null;
    _tCur = now;
    _tPrev = now;
    _blinkAt = -10.0;
  }

  Pose? _origine(double now, List<double>? shape, BotExpression? expr) {
    if (_departFige != null) return _departFige;
    if (_prev == null) return null;
    final prevDef = stateById[_prev]!;
    return _posed(prevDef, math.max(0.0, now - _tPrev), shape, expr);
  }

  Pose _poseComposee(double now) {
    final def = stateById[_cur]!;
    final shape = _shapeAtTime(now);
    final expr = _exprAtTime(now);
    final pose = _posed(def, math.max(0.0, now - _tCur), shape, expr);
    final since = now - _tCur;
    if (since >= def.morph) return pose;
    final origine = _origine(now, shape, expr);
    if (origine == null) return pose;
    return blendPose(
      origine,
      pose,
      Easings.easeOutQuint(clamp(since / def.morph)),
    );
  }

  void setState(BloubState id, double now) {
    if (id == _cur) return;
    final morph = stateById[_cur]!.morph;
    final enPleinFondu = _prev != null && now - _tCur < morph;
    _departFige = enPleinFondu ? _poseComposee(now) : null;
    _prev = _cur;
    _tPrev = _tCur;
    _cur = id;
    _tCur = now;
    if (stateById[id]?.blinkIn == true) _blinkAt = now;
  }

  BotFrame sample(double now) {
    final rScale = scale;
    final def = stateById[_cur]!;
    final shape = _shapeAtTime(now);
    final expr = _exprAtTime(now);
    var pose = _posed(def, math.max(0.0, now - _tCur), shape, expr);
    var decalage = _decalageAtTime(now, _cur);

    final since = now - _tCur;
    final origine = since < def.morph ? _origine(now, shape, expr) : null;
    if (origine != null) {
      final ratio = Easings.easeOutQuint(clamp(since / def.morph));
      pose = blendPose(origine, pose, ratio);
      if (_prev != null) {
        final avant = _decalageAtTime(now, _prev!);
        decalage = Vec2(
          lerp(avant.x, decalage.x, ratio),
          lerp(avant.y, decalage.y, ratio),
        );
      }
    }

    final alive = pose.eyeAlpha > 0.01;
    final look = _lookAtTime(now);
    final life = getLiveliness(
      now,
      wander: alive ? look.wander : 0.0,
      blink: alive,
    );

    final gaze = HeadGaze(
      yaw: lerp(pose.gaze.yaw, look.yaw, look.mix) + life.dYaw - look.spin,
      pitch: lerp(pose.gaze.pitch, look.pitch, look.mix) + life.dPitch,
      roll: pose.gaze.roll + life.dRoll,
    );

    final forced = clamp((now - _blinkAt) / 0.2);
    final forcedLid = forced < 1.0 ? (forced * 2.0 - 1.0).abs() : 1.0;
    final lid = math.min(life.lid, forcedLid);

    final offX = pose.offX + life.driftX;
    final offY = pose.offY + life.driftY;

    final sil = Silhouette(
      radii: pose.sil.radii,
      rot: pose.sil.rot,
      cx: pose.sil.cx + offX,
      cy: pose.sil.cy + offY,
      sx: pose.sil.sx,
      sy: pose.sil.sy * life.breath,
    );
    final bodyPath = closedPath(toPoints(sil, rScale, _pts));

    double bodyRadius(double x, double y) {
      return radiusAtAngle(pose.sil.radii, math.atan2(y, x) - pose.sil.rot);
    }

    final List<RenderedEye> eyes = [];
    if (pose.eyeAlpha > 0.01) {
      final poses = eyePoses(gaze, rScale, pose.split);
      for (int i = 0; i < 2; i++) {
        final e = poses[i];
        if (e.depth <= 0.02) continue;
        final cfg = pose.eyes[i];
        final fit = bodyRadius(e.x, e.y);
        final phi = (cfg.tilt * math.pi) / 180.0;
        final cp = math.cos(phi);
        final sp = math.sin(phi);
        final ax = e.a * cp + e.c * sp;
        final ay = e.b * cp + e.d * sp;
        final cx2 = -e.a * sp + e.c * cp;
        final cy2 = -e.b * sp + e.d * cp;
        final k = getBlinkScale(math.min(lid, cfg.open));
        eyes.add(
          RenderedEye(
            d: capsulePath(cfg.w * rScale, cfg.h * rScale),
            matrix:
                'matrix(${r2(ax)},${r2(ay * k)},${r2(cx2)},${r2(cy2 * k)},${r2(e.x * fit + (offX + decalage.x) * rScale)},${r2(e.y * fit + (offY + decalage.y) * rScale)})',
            alpha: pose.eyeAlpha * clamp(e.depth / 0.12),
          ),
        );
      }
    }

    final List<DotRender> dots = [];
    for (final p in pose.dots) {
      if (p.opacity > 0.01 && p.r > 0.0005) {
        dots.add(
          DotRender(
            x: (p.x + offX) * rScale,
            y: (p.y + offY) * rScale,
            r: p.r * rScale,
            opacity: p.opacity,
            color: p.color,
            depth: p.depth,
            d: p.d,
            rot: p.rot,
          ),
        );
      }
    }

    final nFit = pose.notif != null
        ? bodyRadius(pose.notif!.x, pose.notif!.y)
        : 1.0;
    final nx = pose.notif != null
        ? (pose.notif!.x * nFit + offX) * rScale
        : 0.0;
    final ny = pose.notif != null
        ? (pose.notif!.y * nFit + offY) * rScale
        : 0.0;

    NotifRender? notifObj;
    NotifRender? notchObj;
    if (pose.notif != null) {
      notifObj = NotifRender(
        x: nx,
        y: ny,
        r: pose.notif!.r * rScale,
        notch: pose.notif!.notch,
      );
      notchObj = NotifRender(
        x: nx,
        y: ny,
        r: pose.notif!.notch * rScale,
        notch: pose.notif!.notch,
      );
    }

    final List<ArcRender> outArcs = [];
    for (final a in pose.arcs) {
      if (a.opacity > 0.01) {
        outArcs.add(arcRender(a.seed, a.t, rScale, a.id, a.opacity));
      }
    }

    return BotFrame(
      bodyPath: bodyPath,
      bodyAlpha: pose.bodyAlpha,
      eyes: eyes,
      dots: dots,
      dotsBehind: pose.dotsBehind,
      arcs: outArcs,
      notif: notifObj,
      notch: notchObj,
    );
  }
}
