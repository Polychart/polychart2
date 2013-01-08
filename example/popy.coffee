@examples ?= {}

@examples.popy = (dom) ->
  data = polyjs.data
    json:
      [
        {gr: "Grade 9", p: 10},
        {gr: "Grade 10", p: 40},
        {gr: "Grade 11", p: 50},
      ]
    meta:
      gr: type: "cat"
      p: type: "num"

  data.getRaw ->
  data.derive ((p) -> p + 10), 'p+10'
  data.derive ((p) -> "#{p}%"), 'p%'
  
  c = polyjs.chart
    layers: [
      { data: data, type: 'bar', x:'gr', y:'p' }
      { data: data, type: 'text', x:'gr', y:'p', text: 'p' }
    ]
    guides:
      y: { min: 0, max:100 }
      x: { levels : ["Grade 9", "Grade 10", "Grade 11"] }
    dom: dom
