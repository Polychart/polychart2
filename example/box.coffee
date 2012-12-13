@examples ?= {}

datafn2 = () ->
  item = (i) ->
    mod3: if i % 3 is 0 then "G1" else if i % 3 is 1 then "G2" else "G3"
    value: if i == 99 then 15 else Math.random()*10
  (item(i) for i in [0..200])

@examples.box = (dom) ->
  data = new poly.Data json:datafn2()
  poly.chart
    layers: [
      data: data
      type: 'box'
      x: 'mod3'
      y: 'box(value)'
    ]
    dom: dom
