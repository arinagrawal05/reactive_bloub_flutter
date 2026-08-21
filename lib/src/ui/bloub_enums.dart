/// The avatar's body shape.
enum BloubShape {
  circle,
  pebble,
  squircle,
  capsule,
  triangle,
  cloud,
  droplet,
  flame,
  medal,
  acorn,
  jellyfish,
  clover;
}

/// A facial expression, independent of the current [BloubState].
enum BloubExpression {
  neutral,
  attentif,
  surprised,
  excited,
  happy,
  angry,
  sad,
  suspicious,
  curious,
  proud,
  shy,
  unimpressed;
}

/// An animated state the avatar plays through. Some (like [thinking] or
/// [play]) briefly change the body shape as part of the animation before
/// returning to normal.
enum BloubState {
  /// Resting/default — subtle breathing and occasional blinking.
  idle,

  /// Body splits into three pulsing dots — use while waiting on something.
  thinking,

  /// A quick wink.
  wink,

  /// Eyes go wide — surprise.
  wide,

  /// A mistake reaction — tear drop and an exclamation mark.
  alert,

  /// A notification bubble pops into view.
  notify,

  /// An exclamation mark — a positive, attention-grabbing reaction.
  exclaim,

  /// Body bobs gently — inactive/away.
  sleep,

  /// Spins and darts forward with a colorful swoosh — a "let's go" cue.
  play,

  /// Morphs into a spinning shape with orbiting rings, then settles.
  orbit,

  /// A quick ring flourish — good for lightweight transitions.
  swirl,

  /// Explodes into particles and reforms.
  burst;
}

/// One of the built-in preset paint colors. Pass a custom [Color] to
/// `BloubController.setColor` instead if you need something outside this
/// palette.
enum BloubPredefinedColor {
  black('#000000'),
  brown('#765339'),
  red('#F3483F'),
  orange('#F89822'),
  yellow('#FFCC2E'),
  green('#3DD685'),
  teal('#13CDAC'),
  blue('#2C90FF'),
  purple('#7E4CFF'),
  magenta('#F4407B'),
  grey('#A1AAB4');

  final String hex;
  const BloubPredefinedColor(this.hex);
}
