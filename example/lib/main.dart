import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:reactive_bloub/reactive_bloub.dart';

import 'export_stub.dart' if (dart.library.html) 'export_web.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloub Avatar Playground',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B2D42)),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default standard font
      ),
      home: const PlaygroundScreen(),
    );
  }
}

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  late BloubController _controller;

  bool _followPointer = true;

  BloubShape _selectedShape = BloubShape.circle;
  BloubExpression _selectedExpression = BloubExpression.neutral;
  BloubPredefinedColor _selectedColor = BloubPredefinedColor.black;
  BloubState _selectedState = BloubState.idle;

  static const shapeNames = {
    BloubShape.circle: 'Circle',
    BloubShape.pebble: 'Pebble',
    BloubShape.squircle: 'Squircle',
    BloubShape.capsule: 'Capsule',
    BloubShape.triangle: 'Triangle',
    BloubShape.hexagon: 'Hexagon',
    BloubShape.cloud: 'Cloud',
    BloubShape.droplet: 'Droplet',
    BloubShape.flame: 'Flame',
    BloubShape.brain: 'Brain',
    BloubShape.medal: 'Medal',
    BloubShape.acorn: 'Acorn',
    BloubShape.jellyfish: 'Jellyfish',
    BloubShape.clover: 'Clover',
  };

  static const stateNames = {
    BloubState.idle: 'Idle',
    BloubState.thinking: 'Thinking',
    BloubState.wink: 'Wink',
    BloubState.wide: 'Wide',
    BloubState.alert: 'Alert',
    BloubState.notify: 'Notify',
    BloubState.exclaim: 'Exclaim',
    BloubState.sleep: 'Sleep',
    BloubState.play: 'Play',
    BloubState.orbit: 'Orbit',
    BloubState.swirl: 'Swirl',
    BloubState.burst: 'Burst',
  };

  static const expressionNames = {
    BloubExpression.neutral: 'Neutral',
    BloubExpression.attentif: 'Attentive',
    BloubExpression.surprised: 'Surprised',
    BloubExpression.excited: 'Excited',
    BloubExpression.happy: 'Happy',
    BloubExpression.angry: 'Angry',
    BloubExpression.sad: 'Sad',
    BloubExpression.suspicious: 'Suspicious',
    BloubExpression.curious: 'Curious',
    BloubExpression.proud: 'Proud',
    BloubExpression.shy: 'Shy',
    BloubExpression.unimpressed: 'Unimpressed',
  };

  @override
  void initState() {
    super.initState();
    _controller = BloubController();

    // Set initial configuration
    _controller.setShape(_selectedShape);
    _controller.setExpression(_selectedExpression);
    _controller.updateProperties(predefinedColor: _selectedColor);
    _controller.setState(_selectedState);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateGaze(PointerEvent event, Size size) {
    if (!_followPointer) return;

    final center = Offset(size.width / 2, size.height / 2);
    final dx = event.position.dx - center.dx;
    final dy = event.position.dy - center.dy;

    final yaw = (dx / size.width) * 80.0;
    final pitch = -(dy / size.height) * 80.0;

    _controller.lookAt(yaw: yaw, pitch: pitch);
  }

  void _resetGaze() {
    _controller.resetGaze();
  }

  Widget _buildGridItem({
    required bool isSelected,
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 86,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2B2D42) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 44, height: 44, child: icon),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? const Color(0xFF2B2D42) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Center Avatar Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  onHover: (event) => _updateGaze(
                    event,
                    Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                  onExit: (_) => _resetGaze(),
                  child: Stack(
                    children: [
                      Center(
                        child: BloubAvatar(controller: _controller, size: 340),
                      ),
                      Positioned(
                        bottom: 60,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final bytes = await _controller.exportAsPng(
                                size: 512,
                                // now: _now,
                              );
                              downloadImage(bytes, 'bloub_avatar.png');
                            },
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Export as PNG'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B2D42),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Right Sidebar (Properties)
          Container(
            width: 360,
            color: Colors.white,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                // Shape Selection
                const Text(
                  'Shape',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: shapeNames.entries
                      .map(
                        (e) => _buildGridItem(
                          isSelected: _selectedShape == e.key,
                          label: e.value,
                          icon: _MiniAvatar(
                            shape: e.key,
                            expression: _selectedExpression,
                            color: _selectedColor,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedShape = e.key;
                              _controller.setShape(e.key);
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 32),

                // Expression Selection
                const Text(
                  'Expression',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: expressionNames.entries
                      .map(
                        (e) => _buildGridItem(
                          isSelected: _selectedExpression == e.key,
                          label: e.value,
                          icon: _MiniAvatar(
                            shape: _selectedShape,
                            expression: e.key,
                            color: _selectedColor,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedExpression = e.key;
                              _controller.setExpression(e.key);
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 32),

                // Animations Selection
                const Text(
                  'Animations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: stateNames.entries
                      .map(
                        (e) => _buildGridItem(
                          isSelected: _selectedState == e.key,
                          label: e.value,
                          icon: _MiniAvatar(
                            shape: _selectedShape,
                            expression: _selectedExpression,
                            color: _selectedColor,
                            state: e.key,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedState = e.key;
                              _controller.setState(e.key);
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 32),

                // Color Selection
                const Text(
                  'Colour',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: BloubPredefinedColor.values
                      .map(
                        (c) => InkWell(
                          onTap: () {
                            setState(() {
                              _selectedColor = c;
                              _controller.updateProperties(predefinedColor: c);
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                  c.hex.replaceFirst('#', 'FF'),
                                  radix: 16,
                                ),
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor == c
                                    ? const Color(0xFF2B2D42)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: _selectedColor == c
                                ? Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 40),

                // Toggles
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Follow Cursor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  value: _followPointer,
                  activeThumbColor: const Color(0xFF2B2D42),
                  onChanged: (val) {
                    setState(() {
                      _followPointer = val;
                      if (!val) _resetGaze();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// A simple widget to display a static, un-animated Bloub Avatar for the picker icons
class _MiniAvatar extends StatefulWidget {
  final BloubShape shape;
  final BloubExpression expression;
  final BloubPredefinedColor color;
  final BloubState? state;

  const _MiniAvatar({
    required this.shape,
    required this.expression,
    required this.color,
    this.state,
  });

  @override
  State<_MiniAvatar> createState() => _MiniAvatarState();
}

class _MiniAvatarState extends State<_MiniAvatar> {
  late BloubController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = BloubController();
    _ctrl.setShape(widget.shape);
    _ctrl.setExpression(widget.expression);
    _ctrl.updateProperties(predefinedColor: widget.color);
    if (widget.state != null) {
      _ctrl.setState(widget.state!);
    }

    // Simulate a tiny bit of time so it settles if needed
    Future.microtask(() {
      if (mounted) {
        _ctrl.setShape(widget.shape);
        _ctrl.setExpression(widget.expression);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _MiniAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shape != widget.shape) {
      _ctrl.setShape(widget.shape);
    }
    if (oldWidget.expression != widget.expression) {
      _ctrl.setExpression(widget.expression);
    }
    if (oldWidget.color != widget.color) {
      _ctrl.updateProperties(predefinedColor: widget.color);
    }
    if (oldWidget.state != widget.state && widget.state != null) {
      _ctrl.setState(widget.state!);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BloubAvatar(controller: _ctrl, size: 44);
  }
}
