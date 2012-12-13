@examples ?= {}

datafn = () ->
  a = (i) -> i % 5
  b = (i) -> Math.floor(i / 5)
  value = () -> Math.random()*5
  item = (i) ->
    mod5: a(i)
    floor5: b(i)
    value: value()
  (item(i) for i in [0..24])

@examples.tiles = (dom) ->
  data = new poly.Data json:datafn()
  spec = {
    layers: [
      data: data
      type: 'tile'
      x : 'bin(mod5, 1)'
      y : 'bin(floor5,1)'
      color: 'value'
    ]
    dom: dom
  }
  c = poly.chart spec

@examples.tiles_bw = (dom) ->
  data = new poly.Data json:datafn()
  spec = {
    layers: [
      data: data
      type: 'tile'
      x : 'bin(mod5, 1)'
      y : 'bin(floor5,1)'
      color: 'value'
    ]
    guides:
      color: { scale: poly.scale.gradient(lower: '#FFF', upper:'#000') }
    dom: dom
  }
  c = poly.chart spec

