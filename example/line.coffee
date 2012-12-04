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
    flip: true
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


