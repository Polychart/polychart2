@examples ?= {}

@examples.funnel = (dom) ->
  data = new polyjs.Data
    json:
      segment: ["FirstTime", "FirstTime", "FirstTime", "Return", "Return", "Return", "4+", "4+", "4+"],
      cat: ["A", "B", "C", "A", "B", "C", "A", "B", "C"],
      value: [10,15,20,5,10,18,3,5,8]
    meta:
      segment: type: "cat"
      cat: type: "cat"
      value: type: "num"

  c = polyjs.chart
    layers: [ {
        data: data,
        type: 'bar',
        x: {var: 'segment', sort: 'sum(value)', desc: true},
        y: 'value'
        color: 'cat'
      }
    ]
    guides:
      x:
        renderLine: false
        renderTick: false
        renderLabel: true
        renderGrid: false
      y:
        position: "none"
    coord: polyjs.coord.cartesian(flip: true)
    dom: dom
  c.addHandler polyjs.handler.tooltip()

