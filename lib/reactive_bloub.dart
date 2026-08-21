/// An animated, procedurally-rendered mascot avatar for Flutter.
///
/// The public surface is intentionally small: [BloubAvatar] to render it,
/// [BloubController] to drive it, and three enums ([BloubShape],
/// [BloubExpression], [BloubState]) plus [BloubPredefinedColor] to configure
/// it. Everything else (the rendering engine, its internal pose data) is an
/// implementation detail and is not exported here.
library;

export 'src/ui/bloub_avatar.dart';
export 'src/ui/bloub_controller.dart';
export 'src/ui/bloub_enums.dart';
