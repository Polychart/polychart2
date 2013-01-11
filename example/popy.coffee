@examples ?= {}

@examples.popy_polar = (dom) ->
  data = polyjs.data
    json:
      [
        {gr: "Grade 9", p: 10},
        {gr: "Grade 10", p: 40},
        {gr: "Grade 11", p: 50},
        {gr: "Grade 12", p: 70},
      ]
 
  c = polyjs.chart
    layers: [
      { data: data, type: 'bar', y:'p' }
    ]
    facet:
      type: 'wrap'
      var: 'gr'
    coord:
      type: 'polar'
    guides:
      y: min: 0, max:100, position: 'none', padding: 0
      x: position: 'none', padding: 0
    dom: dom

@examples.popy = (dom) ->
  data = polyjs.data
    json:
      [
        {gr: "Grade 9", p: 10},
        {gr: "Grade 10", p: 40},
        {gr: "Grade 11", p: 50},
        {gr: "Grade 12", p: 70},
      ]

  data.derive ((x) -> x.p + 5), 'p_10'
  data.derive ((x) -> "#{x.p}%"), 'percent'
  
  c = polyjs.chart
    layers: [
      { data: data, type: 'bar', x:'gr', y:'p' }
      { data: data, type: 'text', x:'gr', y:'p_10', text: 'percent', color: {const:'black'} }
    ]
    guides:
      y: { min: 0, max:100 }
      x: { levels : ["Grade 9", "Grade 10", "Grade 11", "Grade 12"] }
    dom: dom

@examples.volexp = (dom) ->
  data = polyjs.data
    json:
      [
        {gr: "Health Care", num: 500}
        {gr: "Events", num: 400}
        {gr: "Recreation", num: 370}
        {gr: "Technology", num: 370}
        {gr: "Animal/Pets", num: 70}
        {gr: "Senior Services", num: 30}
      ]

  data.derive ((x) -> x.num+40), 'p_50'
  data.derive ((x) -> "#{Math.round(x.num/800*100)}%"), 'percent'
  
  c = polyjs.chart
    layers: [
      { data: data, type: 'bar', x: {var: 'gr', sort:'num'}, y:'num' }
      { data: data, type: 'text', x:'gr', y:'p_50', text:'percent', color: {const:'black'}}
    ]
    dom: dom
    guide:
      y: { min: 0, max:700 }
    coord: { type:'cartesian', flip: true }

@examples.rating = (dom) ->
  data = polyjs.data
    json:
      [
        {gr: "Excellent", num: 500}
        {gr: "Very Good", num: 400}
        {gr: "Average", num: 370}
        {gr: "Poor", num: 370}
        {gr: "Terrible", num: 70}
      ]
  
  c = polyjs.chart
    layers: [
      { data: data, type: 'bar', x: {var: 'gr', sort:'num'}, y:'num' }
    ]
    dom: dom
    guide:
      y: { min: 0, max:700 }
    coord: { type:'cartesian', flip: true }
