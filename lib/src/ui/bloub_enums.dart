enum BloubShape {
  circle('cercle'),
  pebble('galet'),
  squircle('squircle'),
  capsule('capsule'),
  triangle('triangle'),
  hexagon('hexagone'),
  cloud('nuage'),
  droplet('goutte'),
  flame('flamme'),
  brain('cerveau'),
  medal('medaille'),
  acorn('gland'),
  jellyfish('pieuvre'),
  clover('trefle');

  final String id;
  const BloubShape(this.id);
}

enum BloubExpression {
  neutral('neutre'),
  attentif('attentif'),
  surprised('surpris'),
  excited('excite'),
  happy('content'),
  laughing('rire'),
  angry('colere'),
  sad('triste'),
  scared('peur'),
  suspicious('suspect'),
  confused('perplexe'),
  curious('curieux'),
  proud('fier'),
  shy('timide'),
  unimpressed('blase'),
  sleepy('sommeil');

  final String id;
  const BloubExpression(this.id);
}

enum BloubState {
  idle('idle'),
  thinking('thinking'),
  wink('wink'),
  wide('wide'),
  alert('alert'),
  notify('notify'),
  exclaim('exclaim'),
  sleep('sleep'),
  egg('egg'),
  hexagon('hexagon'),
  play('play'),
  orbit('orbit'),
  swirl('swirl'),
  burst('burst'),
  comet('comet');

  final String id;
  const BloubState(this.id);
}

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
