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

  c.addHandler (type, e) ->
    data = e.evtData
    if type == 'reset'
      jsondata.shift()
      jsondata.push({index:i++, value:Math.random()*10})
      spec.layers[0].data.update jsondata
      c.make spec
      c.render dom
    if type == 'click'
      alert("You clicked on index: " + data.index.in[0])
    if type == 'select'
      console.log data
      #alert("You clicked on index: " + data.index.in[0])

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
    coord: poly.coord.polar( flip: true)
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

  c.addHandler (type, e) ->
    data = e.evtData
    if type == 'select'
      console.log data
      #alert("You clicked on index: " + data.index.in[0])


@examples.bar_sum= (dom) ->
  jsondata = (
    {index:i, two:(if i%2 is 0 then 'a' else 'b'), value:Math.random()*10} for i in [0..5]
  )
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      data: data
      type: 'bar'
      x : 'two'
      y : 'sum(value)'
      color: 'two'
      id: 'two'
    ]
    guides:
      color: labels:{'a':'Even Numbers', 'b':'Odd Numbers'}, title:'Test'
      x: labels:{'a':'Even Numbers', 'b':'Odd Numbers'}
      y: min:0, max: 30
  }
  c = poly.chart spec
  c.render dom

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, two:(if i%2 is 0 then 'a' else 'b'), value:Math.random()*10})
    spec.layers[0].data.update jsondata
    c.make spec
    c.render dom
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.bar_stack = (dom) ->
  jsondata = (
    {index:i, two:(if i%2 is 0 then 'a' else 'b'), value:Math.random()*10} for i in [0..10]
  )
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      data: data
      type: 'bar'
      x : 'two'
      y : 'value'
      color: 'index'
    ]
    guides:
      color: labels:{'a':'Even Numbers', 'b':'Odd Numbers'}, title:'Test'
      x: labels:{'a':'Even Numbers', 'b':'Odd Numbers'}
  }
  c = poly.chart spec
  c.render dom

  redraw = () ->
    jsondata.push({index:i++, two:(if i%2 is 0 then 'a' else 'b'), value:Math.random()*10})
    spec.layers[0].data.update jsondata
    c.make spec
    c.render dom
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)
