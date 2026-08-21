import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_bloub/reactive_bloub.dart';

void main() {
  test('BloubController exposes the configured shape, color and state', () {
    final controller = BloubController(
      initialShape: BloubShape.hexagon,
      initialPredefinedColor: BloubPredefinedColor.teal,
      initialState: BloubState.idle,
    );

    expect(controller.shape, BloubShape.hexagon);
    expect(controller.predefinedColor, BloubPredefinedColor.teal);
    expect(controller.state, BloubState.idle);
    expect(controller.resolvedColor, isNotNull);
  });

  test('setState/setShape/setExpression update controller state', () {
    final controller = BloubController();

    controller.setState(BloubState.exclaim, 0);
    expect(controller.state, BloubState.exclaim);

    controller.setShape(BloubShape.cloud, 0);
    expect(controller.shape, BloubShape.cloud);

    controller.setExpression(BloubExpression.happy, 0);
    expect(controller.expression, BloubExpression.happy);
  });

  test('a custom color overrides the predefined color when resolving', () {
    final controller = BloubController();
    controller.setColor(custom: const Color(0xFF123456));
    expect(controller.resolvedColor, const Color(0xFF123456));
  });
}
