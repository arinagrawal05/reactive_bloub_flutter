import 'dart:math' as math;
import '../core/face.dart';
import '../core/math.dart';
import '../core/shape.dart';
import '../ui/bloub_enums.dart';
import 'decor.dart';

class EyeCfg {
  final double w;
  final double h;
  final double open;
  final double tilt;

  const EyeCfg({
    required this.w,
    required this.h,
    required this.open,
    this.tilt = 0.0,
  });
}

class Pose {
  final Silhouette sil;
  final double offX;
  final double offY;
  final HeadGaze gaze;
  final double split;
  final List<EyeCfg> eyes;
  final double eyeAlpha;
  final double bodyAlpha;
  final List<DotRender> dots;
  final List<ArcSpec> arcs;
  final NotifRender? notif;
  final bool dotsBehind;

  const Pose({
    required this.sil,
    required this.offX,
    required this.offY,
    required this.gaze,
    required this.split,
    required this.eyes,
    required this.eyeAlpha,
    required this.bodyAlpha,
    required this.dots,
    required this.arcs,
    this.notif,
    required this.dotsBehind,
  });
}

class NotifRender {
  final double x;
  final double y;
  final double r;
  final double notch;

  const NotifRender({
    required this.x,
    required this.y,
    required this.r,
    required this.notch,
  });
}

List<EyeCfg> _pair(double w, double h) {
  return [EyeCfg(w: w, h: h, open: 1.0), EyeCfg(w: w, h: h, open: 1.0)];
}

Pose basePose({
  Silhouette? sil,
  double? offX,
  double? offY,
  HeadGaze? gaze,
  double? split,
  List<EyeCfg>? eyes,
  double? eyeAlpha,
  double? bodyAlpha,
  List<DotRender>? dots,
  List<ArcSpec>? arcs,
  NotifRender? notif,
  bool? dotsBehind,
}) {
  return Pose(
    sil: sil ?? createCircle(1.0),
    offX: offX ?? 0.0,
    offY: offY ?? 0.0,
    gaze: gaze ?? restGaze,
    split: split ?? eyeSplit,
    eyes: eyes ?? _pair(eyeW, eyeH),
    eyeAlpha: eyeAlpha ?? 1.0,
    bodyAlpha: bodyAlpha ?? 1.0,
    dots: dots ?? [],
    arcs: arcs ?? [],
    notif: notif,
    dotsBehind: dotsBehind ?? false,
  );
}

const double barUprightCy = -0.1875;
final List<double> barUprightProfile = profileFromPolygon(
  hullOfCircles(0.0, -0.505, 0.132, 0.0, 0.13, 0.075),
  0.0,
  barUprightCy,
);

final List<double> barItalicProfile = profileFromPolygon(
  hullOfCircles(0.0, -0.2535, 0.1345, 0.0, 0.2535, 0.1345),
  0.0,
  0.0,
);

Silhouette _barUpright({
  double rot = 0.0,
  double cx = 0.0,
  double cy = barUprightCy,
  double sx = 1.0,
  double sy = 1.0,
}) {
  return Silhouette(
    radii: List.from(barUprightProfile),
    rot: rot,
    cx: cx,
    cy: cy,
    sx: sx,
    sy: sy,
  );
}

Silhouette _barItalic({
  double rot = 0.0,
  double cx = 0.0,
  double cy = 0.0,
  double sx = 1.0,
  double sy = 1.0,
}) {
  return Silhouette(
    radii: List.from(barItalicProfile),
    rot: rot,
    cx: cx,
    cy: cy,
    sx: sx,
    sy: sy,
  );
}

final String tearPath = polyPath(
  hullOfCircles(0.0, 0.0, 0.118, 0.0, 0.172, 0.012),
);

const double triOrbit = 0.213;


class StateDef {
  final BloubState id;
  final double duration;
  final double? minDuration;
  final double morph;
  final bool blinkIn;
  final bool baseBody;
  final bool baseFace;
  final Pose Function(double, List<double>?) pose;

  const StateDef({
    required this.id,
    required this.duration,
    this.minDuration,
    required this.morph,
    required this.blinkIn,
    required this.baseBody,
    required this.baseFace,
    required this.pose,
  });
}

double _dotPulse(double t, int index) {
  final p = ((((t - index * 0.5) / 1.5) % 1.0) + 1.0) % 1.0;
  final k = p < 0.5 ? 0.5 - 0.5 * math.cos(p * tau) : 0.0;
  return clamp(k * 2.0);
}

final List<StateDef> states = [
  StateDef(
    id: BloubState.idle,
    duration: 2.4,
    morph: 0.45,
    blinkIn: false,
    baseFace: true,
    baseBody: true,
    pose: (t, shape) => basePose(),
  ),
  StateDef(
    id: BloubState.thinking,
    duration: 2.6,
    morph: 0.4,
    baseFace: false,
    baseBody: false,
    blinkIn: true,
    pose: (t, shape) {
      final mid = _dotPulse(t, 1);
      final emerge = 0.3 + 0.7 * Easings.easeOutCubic(clamp(t / 0.3));
      return basePose(
        sil: createCircle(dotR * (1.0 + (dotPeak - 1.0) * mid), cx: dotX[1]),
        eyeAlpha: 0.0,
        dots: [0, 2].map((i) {
          final k = _dotPulse(t, i);
          return DotRender(
            x: dotX[i] * emerge,
            y: 0.0,
            r: dotR * (1.0 + (dotPeak - 1.0) * k),
            opacity: 0.55 + 0.45 * k,
          );
        }).toList(),
      );
    },
  ),
  StateDef(
    id: BloubState.wink,
    duration: 1.6,
    morph: 0.3,
    blinkIn: true,
    baseFace: false,
    baseBody: true,
    pose: (t, shape) => basePose(
      gaze: const HeadGaze(yaw: -5.37, pitch: 4.55, roll: 6.7),
      split: 16.25,
      eyes: [
        const EyeCfg(w: 0.236, h: 0.464, open: 1.0),
        const EyeCfg(w: 0.447, h: 0.089, open: 1.0),
      ],
    ),
  ),
  StateDef(
    id: BloubState.wide,
    duration: 1.8,
    morph: 0.55,
    blinkIn: true,
    baseFace: false,
    baseBody: true,
    pose: (t, shape) => basePose(
      gaze: const HeadGaze(yaw: 6.92, pitch: -21.96, roll: 11.6),
      split: 18.43,
      eyes: _pair(0.356, 0.875),
    ),
  ),
  StateDef(
    id: BloubState.alert,
    duration: 2.4,
    minDuration: 2.0,
    morph: 0.45,
    baseFace: false,
    baseBody: false,
    blinkIn: false,
    pose: (t, shape) {
      final p = clamp(t / 1.5);
      final travel = Easings.easeInOutCubic(p) * 0.82 - 0.087;
      final back = t > 1.6 ? clamp((t - 1.6) / 0.4) : 0.0;
      final x = travel * (1.0 - back) + 0.1 * back;
      final buzz = math.sin(t * 2.5 * tau) * 0.005;
      final tilt = (17.7 * math.pi) / 180.0;
      return basePose(
        sil: _barItalic(rot: tilt, cx: x, cy: -0.325 - buzz),
        eyeAlpha: 0.0,
        dots: [
          DotRender(
            x: x - math.sin(tilt) * 0.58,
            y: -0.325 + math.cos(tilt) * 0.58 + buzz * 2.8,
            r: 0.118,
            d: tearPath,
            rot: (tilt * 180.0) / math.pi,
            opacity: 1.0,
          ),
        ],
      );
    },
  ),
  StateDef(
    id: BloubState.notify,
    duration: 2.2,
    morph: 0.5,
    blinkIn: true,
    baseFace: false,
    baseBody: true,
    pose: (t, shape) {
      final p = clamp(t / 0.45);
      final pop =
          1.0 + (notifPop - 1.0) * math.sin(p * math.pi) * (1.0 - p * 0.35);
      final r = notifR * (p < 1.0 ? pop : 1.0);
      final a = (notifAngle * math.pi) / 180.0;
      return basePose(
        gaze: const HeadGaze(yaw: -21.94, pitch: -5.82, roll: -12.2),
        split: 18.89,
        eyes: _pair(0.505, 0.498),
        notif: NotifRender(
          x: math.cos(a) * notifDist,
          y: math.sin(a) * notifDist,
          r: r,
          notch: r + notifMargin,
        ),
      );
    },
  ),
  StateDef(
    id: BloubState.exclaim,
    duration: 2.0,
    morph: 0.45,
    baseFace: false,
    baseBody: false,
    blinkIn: false,
    pose: (t, shape) => basePose(
      sil: _barUpright(),
      eyeAlpha: 0.0,
      dots: [const DotRender(x: -0.012, y: 0.526, r: 0.113, opacity: 1.0)],
    ),
  ),
  StateDef(
    id: BloubState.sleep,
    duration: 2.4,
    morph: 0.5,
    baseFace: false,
    baseBody: true,
    blinkIn: false,
    pose: (t, shape) => basePose(
      bodyAlpha: 1.0,
      sil: createCircle(
        1.0,
        sx: 0.1585,
        sy: 0.1585,
        cy: 0.11 + math.sin(t * (tau / 0.6)) * 0.19,
      ),
      offX: 0.0,
      eyeAlpha: 0.0,
    ),
  ),

  StateDef(
    id: BloubState.play,
    duration: 2.0,
    morph: 0.5,
    baseFace: false,
    baseBody: true,
    blinkIn: true,
    pose: (t, shape) {
      final fade = clamp(t / 0.35) * clamp((2.2 - t) / 0.5);
      final List<ArcSpec> specArcs = [];
      for (int i = 0; i < swoosh.length; i++) {
        final s = swoosh[i];
        specArcs.add(
          ArcSpec(
            id: 'sw$i',
            seed: ArcSeed(
              a: s.a,
              k: s.k,
              tilt: s.tilt,
              speed: s.speed,
              phase: s.phase,
              sweep: s.sweep,
              hue: s.hue,
              hueSpan: s.hueSpan,
              width: s.width,
              cx: 0.45 - t * 0.42,
              cy: s.cy,
            ),
            t: t,
            opacity: fade,
          ),
        );
      }
      return basePose(
        sil: createCircle(1.0, cy: triOrbit),
        gaze: const HeadGaze(yaw: 12.0, pitch: -8.0, roll: -6.0),
        split: 15.0,
        eyes: _pair(0.18, 0.34),
        arcs: specArcs,
      );
    },
  ),
  StateDef(
    id: BloubState.orbit,
    duration: 3.4,
    minDuration: 2.5,
    morph: 0.6,
    baseFace: false,
    baseBody: true,
    blinkIn: false,
    pose: (t, shape) {
      final rot = lerp(0.0, tau / 4.0, clamp((t - 1.1) / 0.6));
      final back = Easings.easeInOutCubic(clamp((t - 1.6) / 0.9));
      final sil = createCircle(1.0, rot: rot, cy: triOrbit * (1.0 - back));
      final fade = clamp(t / 0.8) * clamp((3.6 - t) / 0.9);
      final List<ArcSpec> specArcs = [];
      for (int i = 0; i < rings.length; i++) {
        specArcs.add(
          ArcSpec(
            id: 'rg$i',
            seed: rings[i],
            t: t,
            opacity: fade * clamp((t - i * 0.13) / 0.3),
          ),
        );
      }
      return basePose(
        sil: sil,
        gaze: HeadGaze(
          yaw: restGaze.yaw + math.sin(t * 6.5) * 65.0 * (1.0 - back),
          pitch: -4.0 + back * 32.0,
          roll: -13.0,
        ),
        eyes: _pair(0.18, 0.34 + back * 0.07),
        arcs: specArcs,
      );
    },
  ),
  StateDef(
    id: BloubState.swirl,
    duration: 1.3,
    minDuration: 1.3,
    morph: 0.3,
    baseFace: true,
    baseBody: true,
    blinkIn: true,
    pose: (t, shape) {
      final List<ArcSpec> specArcs = [];
      for (int i = 0; i < 3; i++) {
        specArcs.add(
          ArcSpec(
            id: 'sw$i',
            seed: rings[i],
            t: t,
            opacity: clamp((t - i * 0.06) / 0.14) * clamp((1.22 - t) / 0.34),
          ),
        );
      }
      return basePose(arcs: specArcs);
    },
  ),
  StateDef(
    id: BloubState.burst,
    duration: 2.6,
    minDuration: 2.4,
    morph: 0.4,
    baseFace: false,
    baseBody: true,
    blinkIn: false,
    pose: (t, shape) {
      final collapse = 1.0 - clamp(t / 0.35);
      final regrow = clamp((t - 1.0) / 0.2);
      final scale = collapse + (1.0 - collapse) * regrow;
      return basePose(
        sil: createCircle(1.0, sx: scale, sy: scale),
        offX: 0.0,
        eyeAlpha: clamp((t - 1.85) / 0.4),
        dots: getParticles(t, 1.0),
        dotsBehind: true,
      );
    },
  ),
];

final Map<BloubState, StateDef> stateById = {for (var s in states) s.id: s};

final Map<BloubState, double> poses = {
  BloubState.idle: 1.0,
  BloubState.thinking: 1.1,
  BloubState.wink: 0.8,
  BloubState.wide: 0.8,
  BloubState.alert: 0.75,
  BloubState.notify: 0.9,
  BloubState.exclaim: 0.8,
  BloubState.sleep: 0.45,
  BloubState.play: 0.9,
  BloubState.orbit: 1.2,
  BloubState.swirl: 0.5,
  BloubState.burst: 0.45,
};

final List<BloubState> sequence = [
  BloubState.idle,
  BloubState.thinking,
  BloubState.wink,
  BloubState.wide,
  BloubState.alert,
  BloubState.notify,
  BloubState.exclaim,
  BloubState.sleep,
  BloubState.play,
  BloubState.orbit,
  BloubState.burst,
];
