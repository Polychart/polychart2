@examples ?= {}

one = () -> Math.random()*10

@examples.point = (dom) ->
  spec = () ->
    jsondata = ({x:one(), y:one(), c:one()} for i in [0..10])
    data = polyjs.data data:jsondata
    sampleLayer =
      data: data
      type: 'point'
      x: 'x'
      y: 'y'
      color: 'c'
    if Math.random() < 0.33
      sampleLayer.size = 'x'
    else if Math.random() < 0.5
      sampleLayer.size = 'c'

    data:jsondata
    spec:
      layers: [sampleLayer]
      legendPosition: 'bottom'
      guides:
        y :
          position: 'right'
          type:'num', min:0, max:10, ticks:[2,4,6,8],
          labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
        x :
          position: 'top'
          type:'num', min:0, max:10, ticks:[2,4,6,8],
          labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
        color :
          type:'num', min:0, max:10, ticks:[2,4,6,8],
          labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
        size :
          type:'num', min:0, max:10, ticks:[2,4,6,8],
          labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
      dom: dom

  initspec = spec().spec
  c = polyjs.chart(initspec)

  redraw = () ->
    newspec = spec()
    initspec.layers[0].data.update(data:newspec.data)
    c.make(newspec.spec)
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.point_missing = (dom) ->
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
      data:data, type:'point', x:'a', y:'b'
    dom:dom

@examples.point_sampled = (dom) ->
  jsondata = ({x:one(), y:one(), c:one()} for i in [0..1000])
  data = polyjs.data data:jsondata
  c = polyjs.chart
    layer:
      data:data, type:'point', x:'x', y:'y', sample:50
    dom:dom
  redraw = () ->
    c.make()
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.point2 = (dom) ->
  jsondata = [{x:'A',y:2},{x:'B',y:3},{x:'C',y:1}]
  data = polyjs.data({ data: jsondata })
  sampleLayer = {
    dom: dom
    data: data,
    type: 'point',
    x: 'x',
    y: 'y',
    size: {'const': 10},
    color: 'x'
  }
  spec =  { layers: [sampleLayer], dom:dom, legendPosition: 'bottom' }
  c = polyjs.chart(spec)

@examples.point3 = (dom) ->
  jsondata = [{x:'A',y:'X'},{x:'B',y:'Y'},{x:'C',y:'Z'}]
  data = polyjs.data({ data: jsondata })
  sampleLayer = { data: data, type: 'point', x: 'x', y: 'y', color: {const:'#E01B6A'} }
  spec =  { layers: [sampleLayer], dom:dom }
  c = polyjs.chart(spec)

@examples.point3_flip = (dom) ->
  jsondata = [{x:'A',y:'X'},{x:'B',y:'Y'},{x:'C',y:'Z'}]
  data = polyjs.data({ data: jsondata })
  sampleLayer = { data: data, type: 'point', x: 'x', y: 'y', color: {const:'#E01B6A'} }
  spec =  { layers: [sampleLayer], coord: { type:'polar', flip:true } , dom:dom}
  c = polyjs.chart(spec)

  c.addHandler (type, data) ->
    if type in ['click', 'reset']
      console.log data; alert(type)

@examples.errors = (dom) ->
  data2 = {}
  polyjs.chart
    render: false
    layer: {data:data2, type:'point', x:'a', y:'b'}

