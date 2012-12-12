@examples ?= {}

@examples.line = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'line', x : 'index', y : 'value'}
      { data: data, type: 'point', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    dom: dom
  }
  c = poly.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update json:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.line_sum = (dom) ->
  i = 0; s = 0
  next = () ->
    v = Math.random()*10
    s += v
    {index:i++, value:v, total:s}
  jsondata = (next() for i in [0..10])
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'line', x : 'index', y : 'total'}
      { data: data, type: 'point', x : 'index', y : 'total', id: 'index'}
    ]
    guides:
      y: min:0
    dom: dom
  }
  c = poly.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push(next())
    spec.layers[0].data.update json:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.line_flip = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'line', x : 'index', y : 'value'}
      { data: data, type: 'point', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    coord: poly.coord.cartesian(flip:true)
    dom: dom
  }
  c = poly.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update json:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.line_polar = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'line', x : 'index', y : 'value'}
      { data: data, type: 'point', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    coord: poly.coord.polar()
    dom: dom
  }
  c = poly.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update json:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.line_polar_flip = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'line', x : 'index', y : 'value'}
      { data: data, type: 'point', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    coord: poly.coord.polar(flip:true)
    dom: dom
  }
  c = poly.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update json:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)


