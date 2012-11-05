poly = @poly || {}

poly.scaleFns =
  novalue : () -> {v: null, f: 'novalue', t: 'scalefn'}
  upper: (v) -> {v: v, f: 'upper', t: 'scalefn'}
  lower: (v) -> {v: v, f: 'lower', t: 'scalefn'}
  middle: (v) -> {v: v, f: 'middle', t: 'scalefn'}
  jitter: (v) -> {v: v, f: 'jitter', t: 'scalefn'}
  identity: (v) -> {v: v, f: 'identity', t: 'scalefn'}

@poly = poly
