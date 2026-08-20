import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../engine/mascot_engine.dart';
import '../engine/skins.dart';
import '../engine/mascot_expression.dart';
import '../engine/mascot_state.dart';
import 'mascot_painter.dart';
import 'bloub_enums.dart';

class BloubController extends ChangeNotifier {
  late MascotEngine _engine;
  
  BloubShape _shape = BloubShape.circle;
  BloubPredefinedColor? _predefinedColor = BloubPredefinedColor.black;
  Color? _customColor;
  BloubState _state = BloubState.idle;
  BloubExpression? _expression;
  Look _look = noLook;
  
  BloubController({
    BloubShape initialShape = BloubShape.circle,
    BloubPredefinedColor? initialPredefinedColor = BloubPredefinedColor.black,
    Color? initialCustomColor,
    BloubState initialState = BloubState.idle,
    BloubExpression? initialExpression,
  }) {
    _shape = initialShape;
    _predefinedColor = initialPredefinedColor;
    _customColor = initialCustomColor;
    _state = initialState;
    _expression = initialExpression;
    
    _engine = MascotEngine(
      scale: 100.0,
      initial: _state.id,
      shape: shapeById[_shape.id]?.radii,
      expression: _expression != null ? expressionById[_expression!.id] : null,
    );
  }
  
  MascotEngine get engine => _engine;
  
  BloubShape get shape => _shape;
  BloubPredefinedColor? get predefinedColor => _predefinedColor;
  Color? get customColor => _customColor;
  BloubState get state => _state;
  BloubExpression? get expression => _expression;
  Look get look => _look;
  
  // Gets the final resolved color to paint
  Color get resolvedColor {
    if (_customColor != null) return _customColor!;
    final hexStr = _predefinedColor?.hex ?? '#000000';
    final hexNum = hexStr.replaceAll('#', '');
    return Color(int.parse(hexNum.length == 6 ? 'FF$hexNum' : hexNum, radix: 16));
  }
  
  void setShape(BloubShape shape, double now) {
    if (_shape == shape) return;
    _shape = shape;
    _engine.setShape(shapeById[_shape.id]?.radii, now);
    notifyListeners();
  }
  
  void setColor({BloubPredefinedColor? predefined, Color? custom}) {
    _predefinedColor = predefined;
    _customColor = custom;
    notifyListeners();
  }
  
  void setState(BloubState state, double now) {
    if (_state == state) return;
    _state = state;
    _engine.setState(_state.id, now);
    notifyListeners();
  }
  
  void setExpression(BloubExpression? expression, double now) {
    if (_expression == expression) return;
    _expression = expression;
    _engine.setExpression(expression != null ? expressionById[expression.id] : null, now);
    notifyListeners();
  }
  
  void setLook(Look look, double now) {
    _look = look;
    _engine.setLook(look, now);
    notifyListeners();
  }
  
  /// Exports the current visual state of the avatar as a PNG image byte array.
  /// You can provide an arbitrary [size] for the output image.
  /// If [now] is not provided, the engine's current time is used.
  Future<Uint8List> exportAsPng({double size = 512.0, double? now}) async {
    final double t = now ?? 0.0;
    final frame = _engine.sample(t);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    
    // Add 15% padding to prevent the breathing animation or wide shapes from getting trimmed
    final double padding = size * 0.15;
    final double drawSize = size - (padding * 2);
    
    canvas.save();
    canvas.translate(padding, padding);
    final painter = MascotPainter(frame: frame, baseColor: resolvedColor);
    painter.paint(canvas, Size(drawSize, drawSize));
    canvas.restore();
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
