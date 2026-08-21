# reactive_bloub

An animated, procedurally-rendered mascot avatar for Flutter. Every frame is
computed live — no sprite sheets, no Lottie files — so shapes, expressions,
and animated states cross-fade smoothly into each other and blend in any
combination.

- **14 shapes** — circle, pebble, squircle, capsule, triangle, hexagon,
  cloud, droplet, flame, brain, medal, acorn, jellyfish, clover
- **16 expressions** — neutral, happy, excited, sad, angry, curious, proud,
  shy, sleepy, and more
- **15 animated states** — idle, thinking, wink, alert, notify, exclaim,
  sleep, play, orbit, burst, comet, and more
- **11 preset colors**, or any custom `Color`
- Pointer/gaze tracking, PNG export, and a fully reactive `ChangeNotifier`
  controller

## Getting started

```yaml
dependencies:
  reactive_bloub: ^0.1.0
```

## Usage

```dart
import 'package:reactive_bloub/reactive_bloub.dart';

final controller = BloubController(
  initialShape: BloubShape.circle,
  initialPredefinedColor: BloubPredefinedColor.blue,
);

BloubAvatar(controller: controller, size: 120)
```

React to something happening in your app:

```dart
// A right or wrong answer — plays the reaction, then returns to idle on its own
controller.react(correct: true);

// A bigger celebration — level complete, milestone reached — also auto-returns
controller.celebrate();

// While something is loading — loops until you call idle()/react()/celebrate()
controller.think();

// Back to resting
controller.idle();
```

The controller keeps its own clock, so `now` is optional everywhere — pass
one only if you need to synchronize with some other animation clock. See
`example/` for a full playground with a shape/expression/state picker and a
PNG export button.

Change shape, color, or expression directly:

```dart
controller.setShape(BloubShape.hexagon);
controller.setColor(predefined: BloubPredefinedColor.teal);
controller.setExpression(BloubExpression.curious);
```

Track a pointer or UI element:

```dart
controller.lookAt(yaw: 20, pitch: -10);
// later
controller.resetGaze();
```

Export the current frame as a PNG (e.g. for a share card or a static
thumbnail):

```dart
final bytes = await controller.exportAsPng(size: 512);
```

### States that hold vs. states that play once

`BloubState.idle`, `.thinking`, `.notify`, and `.sleep` are sustained
states — they loop for as long as you leave the avatar in them. States like
`.exclaim`, `.alert`, `.wink`, and `.comet` play a fixed pose once and then
just hold their last frame — the engine itself never snaps them back to
idle. Use `react`/`celebrate` for those (they schedule the return to idle
for you); reach for `setState` directly only when you want to hold a state
indefinitely or drive the sequencing yourself.

## Additional information

Dispose the controller when you're done with it, same as any
`ChangeNotifier`:

```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```
