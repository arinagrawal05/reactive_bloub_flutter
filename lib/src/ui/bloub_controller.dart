import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import '../engine/mascot_engine.dart';
import '../engine/mascot_state.dart';
import '../engine/skins.dart';
import '../engine/mascot_expression.dart';
import 'mascot_painter.dart';
import 'bloub_enums.dart';

/// Drives a [BloubAvatar]: what shape/color it is, what state it's animating
/// through, and what expression it's wearing.
///
/// Create one and pass it to a [BloubAvatar]. The controller keeps its own
/// clock, so every setter's `now` is optional — pass one only if you're
/// synchronizing with some other animation; otherwise the controller times
/// itself.
///
/// ```dart
/// final controller = BloubController(
///   initialShape: BloubShape.circle,
///   initialPredefinedColor: BloubPredefinedColor.blue,
/// );
/// // ...
/// BloubAvatar(controller: controller, size: 120)
/// // ...
/// controller.react(correct: true); // e.g. on a right answer — auto-returns to idle
/// ```
class BloubController extends ChangeNotifier {
  late MascotEngine _engine;
  final Stopwatch _clock = Stopwatch()..start();
  bool _disposed = false;
  int _playToken = 0;

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

  /// Seconds elapsed since this controller was created — the clock every
  /// setter defaults to when `now` isn't passed explicitly.
  double get elapsed => _clock.elapsedMicroseconds / 1000000.0;

  /// The underlying rendering engine. Intended for use by [BloubAvatar]
  /// itself; not part of the supported public API for package consumers.
  @internal
  MascotEngine get engine => _engine;

  /// The current body shape.
  BloubShape get shape => _shape;

  /// The current preset color, if one is set (see [customColor]).
  BloubPredefinedColor? get predefinedColor => _predefinedColor;

  /// The current custom color, if one was set via [setColor]. Takes
  /// precedence over [predefinedColor] when resolving [resolvedColor].
  Color? get customColor => _customColor;

  /// The current animated state (e.g. idle, thinking, exclaim).
  BloubState get state => _state;

  /// The current facial expression, if one is set.
  BloubExpression? get expression => _expression;

  /// The final color the avatar is painted with: [customColor] if set,
  /// otherwise [predefinedColor], otherwise black.
  Color get resolvedColor {
    if (_customColor != null) return _customColor!;
    final hexStr = _predefinedColor?.hex ?? '#000000';
    final hexNum = hexStr.replaceAll('#', '');
    return Color(int.parse(hexNum.length == 6 ? 'FF$hexNum' : hexNum, radix: 16));
  }

  /// Morphs the body to [shape].
  void setShape(BloubShape shape, [double? now]) {
    if (_shape == shape) return;
    _shape = shape;
    _engine.setShape(shapeById[_shape.id]?.radii, now ?? elapsed);
    notifyListeners();
  }

  /// Sets the paint color. Pass [predefined] for one of the built-in
  /// palette colors, or [custom] for an arbitrary [Color]; [custom] wins
  /// if both are provided.
  void setColor({BloubPredefinedColor? predefined, Color? custom}) {
    _predefinedColor = predefined;
    _customColor = custom;
    notifyListeners();
  }

  /// Plays [state] (e.g. [BloubState.thinking], [BloubState.exclaim]) and
  /// holds it until something else changes it.
  ///
  /// Sustained states like [BloubState.idle], [BloubState.thinking],
  /// [BloubState.notify] and [BloubState.sleep] loop indefinitely and are
  /// meant to be held for as long as you need — call this again (typically
  /// with [BloubState.idle]) when whatever they represent is over.
  ///
  /// One-shot states like [BloubState.exclaim], [BloubState.alert] and
  /// [BloubState.comet] play a fixed pose and then just hold on their last
  /// frame — they do **not** return to idle by themselves. Prefer [react]
  /// or [celebrate] for those; they call this and schedule the return to
  /// idle for you.
  void setState(BloubState state, [double? now]) {
    if (_state == state) return;
    _state = state;
    _engine.setState(_state.id, now ?? elapsed);
    notifyListeners();
  }

  /// Blends to [expression]. Pass `null` to return to the state's default
  /// expression.
  void setExpression(BloubExpression? expression, [double? now]) {
    if (_expression == expression) return;
    _expression = expression;
    _engine.setExpression(
      expression != null ? expressionById[expression.id] : null,
      now ?? elapsed,
    );
    notifyListeners();
  }

  /// Points the avatar's gaze toward a direction, e.g. to track a pointer
  /// or a UI element. [yaw] and [pitch] are in degrees; [mix] controls how
  /// much this overrides the state's own scripted gaze (0 = ignored, 1 =
  /// fully overridden). Call [resetGaze] to hand control back to the
  /// avatar's own idle animation.
  void lookAt({required double yaw, required double pitch, double mix = 1.0, double? now}) {
    _look = Look(yaw: yaw, pitch: pitch, mix: mix, spin: 0.0, wander: 0.0);
    _engine.setLook(_look, now ?? elapsed);
    notifyListeners();
  }

  /// Hands gaze control back to the avatar's own idle animation, undoing
  /// a prior [lookAt].
  void resetGaze([double? now]) {
    _look = noLook;
    _engine.setLook(_look, now ?? elapsed);
    notifyListeners();
  }

  /// Plays a one-shot reaction — a positive one (e.g. a correct answer) if
  /// [correct] is `true`, otherwise a mistake reaction — then automatically
  /// returns to [BloubState.idle] once the reaction's animation finishes.
  void react({required bool correct, double? now}) {
    _playOnce(correct ? BloubState.exclaim : BloubState.alert, now);
  }

  /// Plays a bigger celebration — use for level/world completion rather
  /// than a single correct answer — then automatically returns to
  /// [BloubState.idle].
  void celebrate([double? now]) {
    _playOnce(BloubState.comet, now);
  }

  void _playOnce(BloubState target, double? now) {
    setState(target, now);
    final duration = stateById[target.id]?.duration ?? 2.0;
    final token = ++_playToken;
    Future.delayed(Duration(milliseconds: (duration * 1000).round()), () {
      if (_disposed || token != _playToken) return;
      setState(BloubState.idle);
    });
  }

  /// Plays the "thinking" state — use while something is loading or a
  /// hint is being computed. This loops indefinitely; call [idle] (or
  /// [react]/[celebrate]) once the wait is over.
  void think([double? now]) {
    setState(BloubState.thinking, now);
  }

  /// Returns to the resting/idle state.
  void idle([double? now]) {
    setState(BloubState.idle, now);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Exports the current visual state of the avatar as a PNG image byte array.
  /// You can provide an arbitrary [size] for the output image.
  /// If [now] is not provided, the controller's own clock is used.
  Future<Uint8List> exportAsPng({double size = 512.0, double? now}) async {
    final double t = now ?? elapsed;
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
