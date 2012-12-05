@examples ?= {}

@examples.point = (dom) ->
  one = () -> Math.random()*10
  spec = () ->
    jsondata = ({x:one(), y:one(), c:one()} for i in [0..10])
    data = new poly.Data json:jsondata
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
      guides:
        y :
          type:'num', min:0, max:10, ticks:[2,4,6,8],
          labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
        x :
          type:'num', min:0, max:10, ticks:[2,4,6,8],
          labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
        color :
          type:'num', min:0, max:10, ticks:[2,4,6,8],
          labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
        size :
          type:'num', min:0, max:10, ticks:[2,4,6,8],
          labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
  initspec = spec().spec
  c = poly.chart(initspec)
  c.render(dom)

  redraw = () ->
    newspec = spec()
    initspec.layers[0].data.update(newspec.data)
    c.make(newspec.spec)
    c.render()
    setTimeout(redraw, 1000)
  setTimeout(redraw, 1000)

@examples.point2 = (dom) ->
  jsondata = [{x:'A',y:2},{x:'B',y:3},{x:'C',y:1}]
  data = new poly.Data({ json: jsondata })
  sampleLayer = {
      data: data,
      type: 'point',
      x: 'x',
      y: 'y',
      size: {'const': 10},
      color: 'x'
    }
  spec =  { layers: [sampleLayer] }
  c = poly.chart(spec)
  c.render(dom)

@examples.point3 = (dom) ->
  jsondata = [{x:'A',y:'X'},{x:'B',y:'Y'},{x:'C',y:'Z'}]
  data = new poly.Data({ json: jsondata })
  sampleLayer = { data: data, type: 'point', x: 'x', y: 'y', color: {const:'#E01B6A'} }
  spec =  { layers: [sampleLayer] }
  c = poly.chart(spec)
  c.render(dom)

@examples.point3_flip = (dom) ->
  jsondata = [{x:'A',y:'X'},{x:'B',y:'Y'},{x:'C',y:'Z'}]
  data = new poly.Data({ json: jsondata })
  sampleLayer = { data: data, type: 'point', x: 'x', y: 'y', color: {const:'#E01B6A'} }
  spec =  { layers: [sampleLayer], coord: poly.coord.polar(flip:true) }
  c = poly.chart(spec)
  c.render(dom)

  c.addHandler (type, data) ->
    if type in ['click', 'reset']
      console.log data; alert(type)

