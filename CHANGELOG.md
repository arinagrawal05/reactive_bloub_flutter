## 0.1.0

* Initial public release.
* `BloubAvatar` widget + `BloubController` driving a procedurally-rendered
  mascot: 14 shapes, 16 expressions, 15 animated states, cross-fading
  transitions, pointer/gaze tracking, and PNG export.
* Added `BloubController.react()`, `.celebrate()`, `.think()`, `.idle()`,
  `.lookAt()`, and `.resetGaze()` convenience methods.
* `BloubController` now owns its own clock — `now` is optional on every
  setter. `react()` and `celebrate()` automatically return to `idle` once
  their one-shot animation finishes, instead of holding on the last frame
  forever.
