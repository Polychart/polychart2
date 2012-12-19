@examples ?= {}

@examples.bar = (dom) ->
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
    if type == 'reset'
      jsondata.shift()
      jsondata.push({index:i++, value:Math.random()*10})
      spec.layers[0].data.update json: jsondata
    if type == 'data'
      c.make spec
    if type == 'click'
      alert("You clicked on index: " + data.index.in[0])
    #if type == 'select' then console.log data

@examples.bar_flip = (dom) ->
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
    coord: polyjs.coord.cartesian(flip: true)
    dom: dom
  }
  c = polyjs.chart spec

  update = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    data.update json:jsondata
    setTimeout(update, 1000)
  setTimeout(update, 1000)

  c.addHandler (type, e) ->
    if type == 'data'
      c.make()

@examples.bar_polar = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new polyjs.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'bar', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      x: type:'num', bw:1
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    coord: polyjs.coord.polar( flip: true)
    dom: dom
  }
  c = polyjs.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    spec.layers[0].data.update json:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.bar_static = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new polyjs.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'bar', x : 'index', y : 'value', id: 'index'}
    ]
    guides:
      x: type:'num', bw:1
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    dom: dom
  }
  c = polyjs.chart spec

@examples.bar_sum= (dom) ->
  jsondata = (
    {index:i, two:(if i%2 is 0 then 'a' else 'b'), value:Math.random()*10} for i in [0..5]
  )
  data = new polyjs.Data json:jsondata
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
    dom: dom
  }
  c = polyjs.chart spec

  redraw = () ->
    jsondata.shift()
    jsondata.push({index:i++, two:(if i%2 is 0 then 'a' else 'b'), value:Math.random()*10})
    spec.layers[0].data.update json:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.bar_stack = (dom) ->
  jsondata = (
    {index:i, two:(if i%2 is 0 then 'a' else 'b'), value:Math.random()*10} for i in [0..10]
  )
  data = new polyjs.Data json:jsondata
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
    dom: dom
  }
  c = polyjs.chart spec

  redraw = () ->
    jsondata.push({index:i++, two:(if i%2 is 0 then 'a' else 'b'), value:Math.random()*10})
    spec.layers[0].data.update json:jsondata
    c.make spec
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.bar_ajax_csv = (dom) ->
  data = new polyjs.Data url:"data/test.csv"
  spec = {
    layers: [
      data: data
      type: 'bar'
      x: 'A'
      y: 'B'
    ]
    dom: dom
    guide:
      y: {type: 'num'}
  }
  c = polyjs.chart spec

@examples.bar_date_binned = (dom) ->
  point = () ->
    time: moment().add('minutes', Math.random()*206232).unix()
    value: Math.random()*2
  data = new polyjs.Data
    json:(point() for i in [0..5000])
    meta: { time: { type: 'date', format: 'unix' } }
  spec = {
    layers: [
      data: data
      type: 'bar'
      x: 'bin("time", "month")'
      y: 'sum(value)'
    ]
    dom: dom
  }
  c = polyjs.chart spec

@examples.bar_date_binned2 = (dom) ->
  point = () ->
    time: moment().add('minutes', Math.random()*23803).unix()
    value: Math.random()
  data = new polyjs.Data
    json:(point() for i in [0..500])
    meta: { time: { type: 'date', format: 'unix' } }
  spec = {
    layers: [ {
        data: data
        type: 'bar'
        x: 'bin(time, day)'
        y: 'median(value)'
      }, {
        data: data
        type: 'line'
        x: 'time'
        y: 'value'
        color: {const: 'black'}
      }
    ]
    dom: dom
  }
  c = polyjs.chart spec


