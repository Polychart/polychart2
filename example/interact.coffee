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
