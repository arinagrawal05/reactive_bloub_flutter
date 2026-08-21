import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_bloub/src/engine/mascot_engine.dart';

void main() {
  test('sample does not crash', () {
    final engine = MascotEngine();
    final frame = engine.sample(0.0);
    expect(frame, isNotNull);
  });
}
