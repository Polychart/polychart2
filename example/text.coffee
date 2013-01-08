@examples ?= {}

@examples.text = (dom) ->
  jsondata = [{x:'A',y:'X'},{x:'B',y:'Y'},{x:'C',y:'Z'}]
  data = polyjs.data({ json: jsondata })
  sampleLayer =
    data: data, type: 'text', x: 'x', y: 'y', text: 'y'
  spec =  { layers: [sampleLayer], coord: polyjs.coord.polar(flip:true) , dom:dom}
  c = polyjs.chart(spec)

  c.addHandler (type, data) ->
    if type in ['click', 'reset']
      console.log data; alert(type)

