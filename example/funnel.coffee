@examples ?= {}

@examples.funnel = (dom) ->
  data = new polyjs.Data
    json:
      segment: ["FirstTime", "FirstTime", "FirstTime", "Return", "Return", "Return", "4+", "4+", "4+"],
      source: ["Referral", "LinkedIn", "Cold Call","Referral", "LinkedIn", "Cold Call","Referral", "LinkedIn", "Cold Call"],
      value: [10,15,20,5,10,18,3,5,8]
    meta:
      segment: type: "cat"
      source: type: "cat"
      value: type: "num"

  c = polyjs.chart
    layers: [ {
        data: data,
        type: 'bar',
        x: {var: 'segment', sort: 'sum(value)', desc: true},
        y: 'value'
        color: 'source'
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
    paddingTop: 50
    height: 300

