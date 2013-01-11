@examples ?= {}

@examples.no_x_bar = (dom) ->
  jsondata = [
    {a:1,b:5,c:'A'},{a:3,b:4,c:'A'},{a:2,b:3,c:'A'}
    {a:2,b:2,c:'B'},{a:1,b:4,c:'B'},{a:2.2,b:3,c:'B'},{a:3,b:3,c:'B'}
  ]
  data = polyjs.data json:jsondata
  polyjs.chart
    layers: [
      { data: data, type: 'bar', y : 'sum(a)', color: 'c'}
    ]
    dom: dom

@examples.no_x = (dom) ->
  jsondata = [
    {a:1,b:5,c:'A'},{a:3,b:4,c:'A'},{a:2,b:3,c:'A'}
    {a:2,b:2,c:'B'},{a:1,b:4,c:'B'},{a:2.2,b:3,c:'B'},{a:3,b:3,c:'B'}
  ]
  data = polyjs.data json:jsondata
  polyjs.chart
    layers: [
      { data: data, type: 'point', y : 'a'}
    ]
    dom: dom

@examples.no_x_pie = (dom) ->
  jsondata = [
    {a:1,b:5,c:'A'},{a:3,b:4,c:'A'},{a:2,b:3,c:'A'}
    {a:2,b:2,c:'B'},{a:1,b:4,c:'B'},{a:2.2,b:3,c:'B'},{a:3,b:3,c:'B'}
  ]
  data = polyjs.data json:jsondata
  polyjs.chart
    layers: [
      { data: data, type: 'bar', y : 'sum(a)', color:'c'}
    ]
    coord:
      type: 'polar'
    guides:
      y: padding: 0, position: 'none'
      x: padding: 0, position: 'none'
    dom: dom

@examples.no_y = (dom) ->
  jsondata = [
    {a:1,b:5,c:'A'},{a:3,b:4,c:'A'},{a:2,b:3,c:'A'}
    {a:2,b:2,c:'B'},{a:1,b:4,c:'B'},{a:2.2,b:3,c:'B'},{a:3,b:3,c:'B'}
  ]
  data = polyjs.data json:jsondata
  polyjs.chart
    layers: [
      { data: data, type: 'point', x : 'a'}
    ]
    dom: dom

