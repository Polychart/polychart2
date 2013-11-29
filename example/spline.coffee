@examples ?= {}

@examples.spline = (dom) ->
  jsondata = ({index: i, value:Math.random()*10} for i in [0..10])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      { data: data, type: 'spline', x : 'index', y : 'value'}
      { data: data, type: 'point', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      y:
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4: 'Four', 6:'Six', 8:'Eight'}
    dom: dom
  }
  c = polyjs.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update data:jsondata
    c.make spec
    setTimeout(redraw,1000)
  setTimeout(redraw, 1000)

@examples.spline_missing2 = (dom) ->
  data = polyjs.data data: [
    {a: 2, b: null}
    {a: undefined, b: 7}
    {a: 9, b: null}
    {a: 5}
    {a: null, b: 3}
    {a: undefined, b: null}
  ]
  polyjs.chart
    layer:
      data:data, type:'spline', x:'a', y:'b'
    dom: dom

@examples.spline_missing = (dom) ->
  data = polyjs.data data: [
    {a: 2, b: 4}
    {a: 3, b: 7}
    {a: 9, b: 10}
    {a: 5}
    {a: null, b: 3}
    {a: undefined, b: null}
  ]
  polyjs.chart
    layer:
      data:data, type:'spline', x:'a', y:'b'
    dom:dom

@examples.spline_sum = (dom) ->
  i = 0; s = 0
  next = () ->
    v = Math.random()*10
    s += v
    {index:i++, value:v, total:s}
  jsondata = (next() for i in [0..10])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      { data: data, type: 'spline', x : 'index', y : 'total'}
      { data: data, type: 'point', x : 'index', y : 'total', id: 'index'}
    ]
    guides:
      y: min:0
    dom: dom
  }
  c = polyjs.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push(next())
    spec.layers[0].data.update data:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

# Flipping for splines is a bit trickier because the current implementation is
# not symmetrical. Fix this.
@examples.spline_flip = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      { data: data, type: 'spline', x : 'index', y : 'value'}
      { data: data, type: 'point', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    coord:
      type: 'cartesian'
      flip: true
    dom: dom
  }
  c = polyjs.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update data:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)


# Note the weird kink in the spline
@examples.spline_static = (dom) ->
  jsondata = [
    {a:1,b:5,c:'A'},{a:3,b:4,c:'A'},{a:2,b:3,c:'A'}
    {a:2,b:2,c:'B'},{a:1,b:4,c:'B'},{a:2.2,b:3,c:'B'},{a:3,b:3,c:'B'}
  ]
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      { data: data, type: 'spline', x : 'a', y : 'b', color:'c'}
    ]
    dom: dom
  }
  c = polyjs.chart spec

@examples.spline_date = (dom) ->
  jsondata = [
    {a:'2012-01-01',b:5,c:'A'},
    {a:'2012-01-02',b:6,c:'A'},
    {a:'2012-01-03',b:3,c:'A'},
    {a:'2012-01-04',b:2,c:'B'},
    {a:'2012-01-05',b:4,c:'B'},
    {a:'2012-01-06',b:3,c:'B'},
    {a:'2012-01-07',b:3,c:'B'}
  ]
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      { data: data, type: 'spline', x : 'a', y : 'b'}
    ]
    dom: dom
  }
  c = polyjs.chart spec

@examples.spline_path = (dom) ->
  jsondata = [
    {a:1,b:5,c:'A'},{a:3,b:4,c:'A'},{a:2,b:3,c:'A'}
    {a:2,b:2,c:'B'},{a:1,b:4,c:'B'},{a:2.2,b:3,c:'B'},{a:3,b:3,c:'B'}
  ]
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      { data: data, type: 'spline', x : 'a', y : 'b', color:'c'}
      { data: data, type: 'point', x : 'a', y : 'b', color:'c'}
    ]
    dom: dom
  }
  c = polyjs.chart spec

@examples.spline_series = (dom) ->
  hestavollandata_raw = [4.3, 5.1, 4.3, 5.2, 5.4, 4.7, 3.5, 4.1, 5.6, 7.4, 6.9,
    7.1, 7.9, 7.9, 7.5, 6.7, 7.7, 7.7, 7.4, 7.0, 7.1, 5.8, 5.9, 7.4, 8.2, 8.5,
    9.4, 8.1, 10.9, 10.4, 10.9, 12.4, 12.1, 9.5, 7.5, 7.1, 7.5, 8.1, 6.8, 3.4,
    2.1, 1.9, 2.8, 2.9, 1.3, 4.4, 4.2, 3.0, 3.0]
  volldata_raw = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.0, 0.3, 0.0, 0.0,
    0.4, 0.0, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6, 1.2, 1.7,
    0.7, 2.9, 4.1, 2.6, 3.7, 3.9, 1.7, 2.3, 3.0, 3.3, 4.8, 5.0, 4.8, 5.0, 3.2,
    2.0, 0.9, 0.4, 0.3, 0.5, 0.4]
  jshdata = for hv, i in hestavollandata_raw
    {index: i, value: hv}
  jsvdata = for vv, i in volldata_raw
    {index: i, value: vv}
  hdata = polyjs.data data:jshdata
  vdata = polyjs.data data:jsvdata
  htooltip = (item) ->
    date = if item.index < 24 then "6. Oct 2009, " else "7. Oct 2009, "
    indexTime = if (item.index % 24) > 9 then (item.index % 24) + ":00" else "0" + (item.index % 24) + ":00"
    windValue = item.value + "m/s"
    date + indexTime + ": " + windValue

  spec = {
    layers: [
      {
        data: hdata
        type: 'spline'
        x: 'index'
        y: 'value'
        color: {const: '#85CD00'}
        size: {const: 3}
      },
      {
        data: hdata
        type: 'point'
        x: 'index'
        y: 'value'
        color: {const: '#88CE02'}
        size: {const: 4}
        tooltip: htooltip
      },
      {
        data: vdata
        type: 'spline'
        x: 'index'
        y: 'value'
        color: {const: '#85CDBA'}
        size: {const: 3}
      },
      {
        data: vdata
        type: 'point'
        x: 'index'
        y: 'value'
        color: {const: '#89CEBB'}
        size: {const: 4}
        tooltip: htooltip
      }
    ]
    guides:
      y: min: 0, max: 13
    width: 1200
    height: 500
    dom : dom
  }
  c = polyjs.chart spec

@examples.spline_polar = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      { data: data, type: 'spline', x : 'index', y : 'value'}
      { data: data, type: 'point', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    coord: { type: 'polar'  }
    dom: dom
  }
  c = polyjs.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update data:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.spline_polar_log = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [1..10])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      { data: data, type: 'spline', x : 'index', y : 'value'}
      { data: data, type: 'point', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
      x:
        scale: {type:'log'}
    coord: { type: 'polar'  }
    dom: dom
  }
  c = polyjs.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update data:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.spline_polar_flip = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      { data: data, type: 'spline', x : 'index', y : 'value'}
      { data: data, type: 'point', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    coord: { type: 'polar', flip:true }
    dom: dom
  }
  c = polyjs.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update data:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.spline_tooltip = (dom) ->
  jsondata = ({index:i, value:Math.sin(Math.random() * Math.PI)} for i in [0..10])
  data = polyjs.data data:jsondata
  spline_tool = (item) ->
    square = item.value *  item.value
    tooltip = "The square of this value is " + square
  spec = {
    layers: [
      { data: data, type: 'spline', x: 'index', y: 'value' }
      { data: data, type: 'point', x:'index', y:'value', tooltip: spline_tool}
    ]
    dom: dom
  }
  c = polyjs.chart spec


