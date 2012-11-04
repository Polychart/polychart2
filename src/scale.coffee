poly = @poly || {}

poly.scaleFns =
  novalue : () -> {v: null, f: 'novalue'}
  upper: (v) -> {v: v, f: 'upper'}
  lower: (v) -> {v: v, f: 'lower'}
  middle: (v) -> {v: v, f: 'middle'}
  jitter: (v) -> {v: v, f: 'jitter'}
  identity: (v) -> {v: v, f: 'identity'}

@poly = poly
