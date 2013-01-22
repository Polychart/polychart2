@examples ?= {}

@examples.interact_bar = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = polyjs.data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'bar', x : 'index', y : 'value', id: 'index', opacity:'value'}
    ]
    guides:
      x: type:'num', bw:1
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    dom: dom
  }
  c = polyjs.chart spec

  c.addHandler (type, e) ->
    data = e.evtData
    if type == 'click'
      alert("You clicked on index: " + data.index.in[0])
    if type == 'select'
      console.log data
  c.addHandler polyjs.handler.tooltip()

@examples.interact_point = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = polyjs.data json:jsondata
  spec = {
    layers: [
      data: data, type: 'point', x : 'index', y : 'value'
    ]
    dom: dom
  }
  c = polyjs.chart spec

  c.addHandler polyjs.handler.tooltip()
  c.addHandler (type, e) ->
    data = e.evtData
    if type == 'click'
      alert("You clicked on index: " + data.index.in[0])
  c.addHandler polyjs.handler.tooltip()
    #if type == 'select' then console.log data

@examples.interact_line = (dom) ->
  jsondata = ({index:i, k:""+i%2, value:Math.random()*10} for i in [0..10])
  data = polyjs.data json:jsondata
  spec = {
    layers: [
      data: data, type: 'line', x : 'index', y : 'value', color:'k'
    ]
    dom: dom
  }
  c = polyjs.chart spec

  c.addHandler polyjs.handler.tooltip()
  c.addHandler (type, e) ->
    data = e.evtData
    if type == 'click'
      alert("You clicked on index: " + data.k.in[0])
    #if type == 'select' then console.log data

@examples.interact_path = (dom) ->
  jsondata = ({index:i, k:""+i%2, value:Math.random()*10} for i in [0..10])
  data = polyjs.data json:jsondata
  spec = {
    layers: [
      data: data, type: 'path', x : 'index', y : 'value', color:'k'
    ]
    dom: dom
  }
  c = polyjs.chart spec

  c.addHandler (type, e) ->
    data = e.evtData
    if type == 'click'
      alert("You clicked on index: " + data.k.in[0])
    #if type == 'select' then console.log data

@examples.interact_tiles = (dom) ->
  datafn = () ->
    a = (i) -> i % 5
    b = (i) -> Math.floor(i / 5)
    value = () -> Math.random()*5
    item = (i) ->
      mod5: a(i)
      floor5: b(i)
      value: value()
    (item(i) for i in [0..24])

  data = polyjs.data json:datafn()
  spec = {
    layers: [
      data: data
      type: 'tile'
      x : 'bin(mod5, 1)'
      y : 'bin(floor5,1)'
      color: 'value'
    ]
    dom: dom
  }
  c = polyjs.chart spec
  c.addHandler polyjs.handler.tooltip()

@examples.interact_twocharts = (dom, dom2) ->
  data1 = polyjs.data json: [
    { city: 'tomato', area: 235}
    { city: 'junkie', area: 135}
    { city: 'banana', area: 335}
  ]
  data2 = polyjs.data json: [
    { city:'tomato', month: 1, population: 2352 }
    { city:'tomato', month: 2, population: 2332 }
    { city:'tomato', month: 3, population: 2342 }
    { city:'tomato', month: 4, population: 2252 }
    { city:'tomato', month: 5, population: 2292 }
    { city:'tomato', month: 6, population: 2292 }
    { city:'tomato', month: 7, population: 2222 }
    { city:'junkie', month: 1, population: 4352 }
    { city:'junkie', month: 2, population: 3332 }
    { city:'junkie', month: 3, population: 3342 }
    { city:'junkie', month: 4, population: 4252 }
    { city:'junkie', month: 5, population: 4292 }
    { city:'junkie', month: 6, population: 3292 }
    { city:'junkie', month: 7, population: 3222 }
    { city:'banana', month: 1, population: 1352 }
    { city:'banana', month: 2, population: 1332 }
    { city:'banana', month: 3, population: 1342 }
    { city:'banana', month: 4, population: 1252 }
    { city:'banana', month: 5, population: 2002 }
    { city:'banana', month: 6, population: 1292 }
    { city:'banana', month: 7, population: 1222 }
  ]
  spec1 =
    layer:
      data: data1
      type: 'bar'
      x: {var: 'city', sort: 'area', asc: false}
      y: 'area'
      color: 'city'
    dom: dom
  spec2 =
    layer:
      data: data2
      type: 'area'
      x: 'month'
      y: 'population'
      filter: city: in: ['tomato']
    guide:
      y: min: 0, max:5000
    title: 'tomato'
    dom: dom2

  c1 = polyjs.chart spec1
  c2 = null

  c1.addHandler (type, e) ->
    if type is 'click'
      data = e.evtData
      filter = city: data.city
      spec2.layer.filter = filter
      spec2.layer.color = const: e.attrs.fill
      spec2.title = filter.city.in[0]
      if not c2
        c2 = polyjs.chart spec2
      else
        c2.make spec2
