import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'bloub_controller.dart';
import 'mascot_painter.dart';

/// Renders the mascot driven by [controller].
///
/// The widget owns its own animation ticker, so it repaints every frame
/// without you needing to drive it externally. Give [controller] to
/// `dispose()` when the owning widget is done with it — the avatar doesn't
/// take ownership of it.
///
/// ```dart
/// BloubAvatar(controller: myController, size: 120)
/// ```
class BloubAvatar extends StatefulWidget {
  /// Drives what the avatar looks like and how it animates.
  final BloubController controller;

  /// Side length of the (square) avatar.
  final double size;

  const BloubAvatar({
    super.key,
    required this.controller,
    this.size = 200.0,
  });

  @override
  State<BloubAvatar> createState() => _BloubAvatarState();
}

class _BloubAvatarState extends State<BloubAvatar> with SingleTickerProviderStateMixin {
  // This ticker only schedules a repaint every frame — the actual time
  // value comes from the controller's own clock, so it stays in sync with
  // whatever `now` (or lack of one) was used to trigger a state change.
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _ticker = createTicker((_) => setState(() {}));
    _ticker.start();
  }

  @override
  void didUpdateWidget(BloubAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    // Engine state has changed via controller, will trigger repaint automatically
    // due to ticker, but we might want to manually kick something in the future.
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.controller.engine.sample(widget.controller.elapsed);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: widget.controller.resolvedColor),
        duration: const Duration(milliseconds: 300),
        builder: (context, color, child) {
          return CustomPaint(
            painter: MascotPainter(
              frame: frame,
              baseColor: color ?? widget.controller.resolvedColor,
            ),
          );
        },
      ),
    );
  }
}
