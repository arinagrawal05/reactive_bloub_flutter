import 'package:flutter_test/flutter_test.dart';
import 'package:bloub_avatar/src/engine/mascot_engine.dart';
import 'package:bloub_avatar/src/core/shape.dart';

void main() {
  test('sample does not crash', () {
    final engine = MascotEngine();
    final frame = engine.sample(0.0);
    expect(frame, isNotNull);
  });
}
