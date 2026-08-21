import 'package:flutter/material.dart';
import 'package:reactive_bloub/reactive_bloub.dart';
// Note: The full interactive playground is located in playground.dart. 
// This file is a minimal example for pub.dev to demonstrate basic usage.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BloubSimpleExample(),
    );
  }
}

class BloubSimpleExample extends StatefulWidget {
  const BloubSimpleExample({super.key});

  @override
  State<BloubSimpleExample> createState() => _BloubSimpleExampleState();
}

class _BloubSimpleExampleState extends State<BloubSimpleExample> {
  // 1. Initialize the controller
  late final BloubController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BloubController(
      initialShape: BloubShape.circle,
      initialState: BloubState.idle,
      initialExpression: BloubExpression.happy,
      initialPredefinedColor: BloubPredefinedColor.blue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 2. Drop the BloubAvatar into your UI! (Plug and play)
            BloubAvatar(
              controller: _controller,
              size: 250,
            ),
            const SizedBox(height: 40),
            
            // 3. Control it!
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => _controller.react(correct: true),
                  child: const Text("Success Reaction"),
                ),
                ElevatedButton(
                  onPressed: () => _controller.celebrate(),
                  child: const Text("Celebrate!"),
                ),
                ElevatedButton(
                  onPressed: () => _controller.setShape(BloubShape.cloud),
                  child: const Text("Morph to Cloud"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
