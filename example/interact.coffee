@examples ?= {}

@examples.interact_bar = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new polyjs.Data json:jsondata
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
    #if type == 'select' then console.log data
  c.addHandler polyjs.handler.tooltip()

@examples.interact_point = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new polyjs.Data json:jsondata
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
    #if type == 'select' then console.log data

@examples.interact_line = (dom) ->
  jsondata = ({index:i, k:""+i%2, value:Math.random()*10} for i in [0..10])
  data = new polyjs.Data json:jsondata
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
  data = new polyjs.Data json:jsondata
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


