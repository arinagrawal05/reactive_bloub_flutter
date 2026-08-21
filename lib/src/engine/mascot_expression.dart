import '../core/face.dart';
import '../core/math.dart';
import '../ui/bloub_enums.dart';
import 'mascot_state.dart';

class BotExpression {
  final BloubExpression id;
  final HeadGaze gaze;
  final double split;
  final List<EyeCfg> eyes;

  const BotExpression({
    required this.id,
    required this.gaze,
    required this.split,
    required this.eyes,
  });
}

EyeCfg _eye(double w, double h, [double tilt = 0.0, double open = 1.0]) {
  return EyeCfg(w: w, h: h, tilt: tilt, open: open);
}

List<EyeCfg> _pair(double w, double h, [double tilt = 0.0, double open = 1.0]) {
  return [_eye(w, h, tilt, open), _eye(w, h, -tilt, open)];
}

final List<BotExpression> expressions = [
  BotExpression(
    id: BloubExpression.neutral,
    gaze: restGaze,
    split: eyeSplit,
    eyes: [_eye(eyeW, eyeH), _eye(eyeW, eyeH)],
  ),
  BotExpression(
    id: BloubExpression.attentif,
    gaze: const HeadGaze(yaw: 4, pitch: 5, roll: -4),
    split: 16,
    eyes: _pair(0.21, 0.44),
  ),
  BotExpression(
    id: BloubExpression.surprised,
    gaze: const HeadGaze(yaw: 3, pitch: -3, roll: 0),
    split: 19,
    eyes: _pair(0.45, 0.47),
  ),
  BotExpression(
    id: BloubExpression.excited,
    gaze: const HeadGaze(yaw: 6, pitch: -14, roll: 0),
    split: 19.5,
    eyes: _pair(0.4, 0.56, -10),
  ),
  BotExpression(
    id: BloubExpression.happy,
    gaze: const HeadGaze(yaw: 5, pitch: 15, roll: 0),
    split: 18,
    eyes: _pair(0.35, 0.12, 25),
  ),
  BotExpression(
    id: BloubExpression.angry,
    gaze: const HeadGaze(yaw: 3, pitch: 7, roll: 0),
    split: 17,
    eyes: _pair(0.34, 0.15, 30),
  ),
  BotExpression(
    id: BloubExpression.sad,
    gaze: const HeadGaze(yaw: 3, pitch: -13, roll: 0),
    split: 16,
    eyes: _pair(0.22, 0.4, -28),
  ),
  BotExpression(
    id: BloubExpression.suspicious,
    gaze: const HeadGaze(yaw: 20, pitch: 10, roll: -10),
    split: 15,
    eyes: [_eye(0.15, 0.4, -5), _eye(0.3, 0.1, 20)],
  ),
  BotExpression(
    id: BloubExpression.curious,
    gaze: const HeadGaze(yaw: 16, pitch: -9, roll: -15),
    split: 16.5,
    eyes: [_eye(0.24, 0.46, -8), _eye(0.2, 0.38, -8)],
  ),
  BotExpression(
    id: BloubExpression.proud,
    gaze: const HeadGaze(yaw: 5, pitch: 17, roll: 0),
    split: 17,
    eyes: _pair(0.3, 0.15, 18),
  ),
  BotExpression(
    id: BloubExpression.shy,
    gaze: const HeadGaze(yaw: -19, pitch: -14, roll: -7),
    split: 14,
    eyes: _pair(0.17, 0.3),
  ),
  BotExpression(
    id: BloubExpression.unimpressed,
    gaze: const HeadGaze(yaw: -22, pitch: 2, roll: 0),
    split: 16,
    eyes: _pair(0.3, 0.12),
  ),
];

final Map<BloubExpression, BotExpression> expressionById = {
  for (var e in expressions) e.id: e,
};
const BloubExpression defaultExpression = BloubExpression.neutral;

EyeCfg _lerpEyeCfg(EyeCfg a, EyeCfg b, double t) {
  return EyeCfg(
    w: lerp(a.w, b.w, t),
    h: lerp(a.h, b.h, t),
    tilt: lerp(a.tilt, b.tilt, t),
    open: lerp(a.open, b.open, t),
  );
}

BotExpression blendExpression(BotExpression a, BotExpression b, double t) {
  return BotExpression(
    id: b.id,
    gaze: HeadGaze(
      yaw: lerp(a.gaze.yaw, b.gaze.yaw, t),
      pitch: lerp(a.gaze.pitch, b.gaze.pitch, t),
      roll: lerp(a.gaze.roll, b.gaze.roll, t),
    ),
    split: lerp(a.split, b.split, t),
    eyes: [
      _lerpEyeCfg(a.eyes[0], b.eyes[0], t),
      _lerpEyeCfg(a.eyes[1], b.eyes[1], t),
    ],
  );
}
