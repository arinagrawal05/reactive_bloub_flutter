import 'dart:math' as math;
import '../core/math.dart';
import '../core/shape.dart';
import '../core/profiles.dart';

class BotShape {
  final String id;
  final List<double> radii;

  const BotShape({required this.id, required this.radii});
}

List<double> _normalize(List<double> radii, [double maxVal = 1.0]) {
  double peak = 0.0;
  for (final r in radii) {
    if (r > peak) peak = r;
  }
  if (peak <= 0.0) return radii;
  final k = maxVal / peak;
  return radii.map((r) => r * k).toList();
}

final List<BotShape> shapes = [
  BotShape(id: 'cercle', radii: List.filled(profileSamples, 1.0)),
  BotShape(id: 'galet', radii: _normalize(
    List.generate(profileSamples, (i) {
      final a = (i / profileSamples) * tau;
      return 1.0 + 0.075 * math.cos(2.0 * a + 0.5) + 0.035 * math.cos(3.0 * a + 2.1);
    }), 1.02
  )),
  BotShape(id: 'squircle', radii: _normalize(superellipseProfile(4.2), 1.15)),
  BotShape(id: 'capsule', radii: profileFromPolygon(
    hullOfCircles(-0.42, 0.0, 0.62, 0.42, 0.0, 0.62), 0.0, 0.0
  )),
  BotShape(id: 'triangle', radii: regularPolygonProfile(3, 1.12, 0.34, -90.0)),
  BotShape(id: 'hexagone', radii: regularPolygonProfile(6, 1.04, 0.26, 0.0)),
  BotShape(id: 'nuage', radii: _normalize(unionOfCirclesProfile([
    CircleDef(x: -0.44, y: 0.2, r: 0.54),
    CircleDef(x: 0.46, y: 0.2, r: 0.5),
    CircleDef(x: 0.02, y: 0.3, r: 0.6),
    CircleDef(x: -0.24, y: -0.3, r: 0.48),
    CircleDef(x: 0.3, y: -0.24, r: 0.44),
  ]), 1.02)),
  BotShape(id: 'goutte', radii: _normalize(profileFromPolygon(
    hullOfCircles(0.0, 0.28, 0.66, 0.0, -0.96, 0.05), 0.0, 0.0
  ), 1.04)),
  BotShape(id: 'flamme', radii: _normalize(smoothProfile(unionOfCirclesProfile([
    CircleDef(x: 0.0, y: 0.3, r: 0.5),
    CircleDef(x: -0.2, y: 0.1, r: 0.4),
    CircleDef(x: 0.0, y: -0.2, r: 0.35),
    CircleDef(x: 0.15, y: -0.5, r: 0.15),
  ]), 16), 1.05)),
  BotShape(id: 'cerveau', radii: _normalize(unionOfCirclesProfile([
    CircleDef(x: -0.2, y: -0.2, r: 0.35),
    CircleDef(x: 0.2, y: -0.2, r: 0.35),
    CircleDef(x: -0.4, y: 0.1, r: 0.3),
    CircleDef(x: 0.4, y: 0.1, r: 0.3),
    CircleDef(x: -0.2, y: 0.3, r: 0.35),
    CircleDef(x: 0.2, y: 0.3, r: 0.35),
    CircleDef(x: 0.0, y: 0.0, r: 0.45),
  ]), 1.05)),
  BotShape(id: 'medaille', radii: _normalize(unionOfCirclesProfile([
    CircleDef(x: 0.0, y: -0.2, r: 0.5),
    CircleDef(x: -0.25, y: 0.5, r: 0.2),
    CircleDef(x: 0.25, y: 0.5, r: 0.2),
    CircleDef(x: -0.35, y: 0.3, r: 0.15),
    CircleDef(x: 0.35, y: 0.3, r: 0.15),
  ]), 1.05)),
  BotShape(id: 'gland', radii: _normalize(unionOfCirclesProfile([
    CircleDef(x: 0.0, y: 0.2, r: 0.5),
    CircleDef(x: 0.0, y: -0.2, r: 0.6),
    CircleDef(x: 0.0, y: -0.6, r: 0.15),
  ]), 1.05)),
  BotShape(id: 'pieuvre', radii: _normalize(unionOfCirclesProfile([
    CircleDef(x: 0.0, y: -0.2, r: 0.6),
    CircleDef(x: -0.4, y: 0.4, r: 0.2),
    CircleDef(x: -0.15, y: 0.45, r: 0.2),
    CircleDef(x: 0.15, y: 0.45, r: 0.2),
    CircleDef(x: 0.4, y: 0.4, r: 0.2),
  ]), 1.05)),
  BotShape(id: 'trefle', radii: _normalize(unionOfCirclesProfile([
    CircleDef(x: -0.4, y: -0.4, r: 0.5),
    CircleDef(x: 0.4, y: -0.4, r: 0.5),
    CircleDef(x: -0.4, y: 0.4, r: 0.5),
    CircleDef(x: 0.4, y: 0.4, r: 0.5),
  ]), 1.1)),
];

final Map<String, BotShape> shapeById = {for (var s in shapes) s.id: s};
const String defaultShape = 'cercle';
