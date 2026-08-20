import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'bloub_controller.dart';
import 'mascot_painter.dart';

class BloubAvatar extends StatefulWidget {
  final BloubController controller;
  final double size;

  const BloubAvatar({
    Key? key,
    required this.controller,
    this.size = 200.0,
  }) : super(key: key);

  @override
  State<BloubAvatar> createState() => _BloubAvatarState();
}

class _BloubAvatarState extends State<BloubAvatar> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _now = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _ticker = createTicker((elapsed) {
      setState(() {
        _now = elapsed.inMicroseconds / 1000000.0;
      });
    });
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
    final frame = widget.controller.engine.sample(_now);
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: MascotPainter(
          frame: frame,
          baseColor: widget.controller.resolvedColor,
        ),
      ),
    );
  }
}
