@examples ?= {}

@examples.text = (dom) ->
  jsondata = [{x:'A',y:'X'},{x:'B',y:'Y'},{x:'C',y:'Z'}]
  data = new gg.Data({ json: jsondata })
  sampleLayer =
    data: data, type: 'text', x: 'x', y: 'y', text: 'y'
  spec =  { layers: [sampleLayer], coord: gg.coord.polar(flip:true) , dom:dom}
  c = gg.chart(spec)

  c.addHandler (type, data) ->
    if type in ['click', 'reset']
      console.log data; alert(type)

