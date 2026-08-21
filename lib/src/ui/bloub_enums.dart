/// The avatar's body shape.
enum BloubShape {
  circle('cercle'),
  pebble('galet'),
  squircle('squircle'),
  capsule('capsule'),
  triangle('triangle'),
  cloud('nuage'),
  droplet('goutte'),
  flame('flamme'),
  medal('medaille'),
  acorn('gland'),
  jellyfish('pieuvre'),
  clover('trefle');

  final String id;
  const BloubShape(this.id);
}

/// A facial expression, independent of the current [BloubState].
enum BloubExpression {
  neutral('neutre'),
  attentif('attentif'),
  surprised('surpris'),
  excited('excite'),
  happy('content'),
  angry('colere'),
  sad('triste'),
  suspicious('suspect'),
  curious('curieux'),
  proud('fier'),
  shy('timide'),
  unimpressed('blase');

  final String id;
  const BloubExpression(this.id);
}

/// An animated state the avatar plays through. Some (like [thinking] or
/// [play]) briefly change the body shape as part of the animation before
/// returning to normal.
enum BloubState {
  /// Resting/default — subtle breathing and occasional blinking.
  idle('idle'),

  /// Body splits into three pulsing dots — use while waiting on something.
  thinking('thinking'),

  /// A quick wink.
  wink('wink'),

  /// Eyes go wide — surprise.
  wide('wide'),

  /// A mistake reaction — tear drop and an exclamation mark.
  alert('alert'),

  /// A notification bubble pops into view.
  notify('notify'),

  /// An exclamation mark — a positive, attention-grabbing reaction.
  exclaim('exclaim'),

  /// Body bobs gently — inactive/away.
  sleep('sleep'),

  /// Spins and darts forward with a colorful swoosh — a "let's go" cue.
  play('play'),

  /// Morphs into a spinning shape with orbiting rings, then settles.
  orbit('orbit'),

  /// A quick ring flourish — good for lightweight transitions.
  swirl('swirl'),

  /// Explodes into particles and reforms.
  burst('burst');

  final String id;
  const BloubState(this.id);
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
