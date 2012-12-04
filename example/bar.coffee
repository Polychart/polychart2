@examples ?= {}

@examples.bar = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'bar', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      x: type:'num', bw:1
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
  }
  c = poly.chart spec
  c.render dom

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update jsondata
    c.make spec
    c.render dom
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.bar_flip = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'bar', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      x: type:'num', bw:1
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    coord: poly.coord.cartesian(flip: true)
  }
  c = poly.chart spec
  c.render dom

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update jsondata
    c.make spec
    c.render dom
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.bar_polar = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'bar', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      x: type:'num', bw:1
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    coord: poly.coord.polar()
  }
  c = poly.chart spec
  c.render dom

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update jsondata
    c.make spec
    c.render dom
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.bar_static = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'bar', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      x: type:'num', bw:1
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
  }
  c = poly.chart spec
  c.render dom


