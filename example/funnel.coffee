@examples ?= {}

@examples.funnel = (dom) ->
  data = polyjs.data
    data:
      segment: ["FirstTime", "FirstTime", "FirstTime", "Return", "Return", "Return", "4+", "4+", "4+"],
      source: ["Referral", "LinkedIn", "Cold Call","Referral", "LinkedIn", "Cold Call","Referral", "LinkedIn", "Cold Call"],
      value: [10,15,20,5,10,18,3,5,8]

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
    coord:
      type: 'cartesian'
      flip: true
    dom: dom
    paddingTop: 50
    height: 300

@examples.funnelerr1 = (dom) ->
  data = polyjs.data
    data:
      segment: ["FirstTime", "FirstTime", "FirstTime", "Return", "Return", "Return", "4+", "4+", "4+"],
      source: ["Referral", "LinkedIn", "Cold Call","Referral", "LinkedIn", "Cold Call","Referral", "LinkedIn", "Cold Call"],
      value: [10,15,20,5,10,18,3,5,8]

  c = polyjs.chart
    layers: [ {
        data: data,
        type: 'bar',
        x: {var: 'segment', sort: 'sum(value)', desc: true},
        y: 'value'
        color: 'source'
      }
    ]
    title:'This is a Big Graph Title'
    legendPosition:'bottom'
    guides:
      x:
        renderLine: false
        renderTick: false
        renderLabel: true
        renderGrid: false
      y:
        position: "none"
      color:
        title:'This is another big title the overlaps graph area'
    coord:
      type: 'cartesian'
      flip: true
    dom: dom
    paddingTop: 50
    height: 300

