@examples ?= {}

@examples.text = (dom) ->
  jsondata = [{x:'A',y:'X'},{x:'B',y:'Y'},{x:'C',y:'Z'}]
  data = polyjs.data({ json: jsondata })
  sampleLayer =
    data: data, type: 'text', x: 'x', y: 'y', text: 'y'
  spec =  { layers: [sampleLayer], coord: { type:'polar', flip:true } , dom:dom}
  c = polyjs.chart(spec)

  c.addHandler (type, data) ->
    if type in ['click', 'reset']
      console.log data; alert(type)

@examples.text_size = (dom) ->
  jsondata = [{x:'A',y:'X',z:5},{x:'B',y:'Y',z:2},{x:'C',y:'Z',z:3}]
  data = polyjs.data({ json: jsondata })
  sampleLayer =
    data: data, type: 'text', x: 'x', y: 'y', text: 'y', size: {const: 32}
  spec =  { layers: [sampleLayer], coord: { type:'polar', flip:true } , dom:dom}
  c = polyjs.chart(spec)

  c.addHandler (type, data) ->
    if type in ['click', 'reset']
      console.log data; alert(type)
