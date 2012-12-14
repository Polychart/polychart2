@examples ?= {}

@examples.area_static = (dom) ->
  jsondata = [
    {a:1,b:5,c:'A'},{a:3,b:4,c:'A'},{a:2,b:3,c:'A'}
    {a:2,b:2,c:'B'},{a:1,b:4,c:'B'},{a:2.2,b:3,c:'B'},{a:3,b:3,c:'B'}
  ]
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'area', x : 'a', y : 'b', color:'c'}
    ]
    guides:
      x: title: 'The x-axis'
      y: title: 'The y-axis'
      color: title:'Some Color'
    dom: dom
  }
  c = poly.chart spec

@examples.area_single = (dom) ->
  jsondata = ({index:i, value:Math.random()*10} for i in [0..10])
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'area', x : 'index', y : 'value'}
    ]
    guides:
      y :
        type:'num', min:0, max:10, ticks:[2,4,6,8],
        labels:{2: 'Two', 4:'Four', 6:'Six', 8:'Eight'}
    dom: dom
  }
  c = poly.chart spec

  update = () ->
    jsondata.shift()
    jsondata.push({index:i++, value:Math.random()*10})
    data.update json:jsondata
    setTimeout(update, 1000)
  setTimeout(update, 1000)

  c.addHandler (type, e) -> if type == 'data' then c.make()

@examples.area_double = (dom) ->
  even = (i) -> if i % 2 then "Odd" else "Even"
  value = () -> 2 + Math.random()*5
  item = (i) -> {index:Math.floor(i/2), even: even(i), value:value()}
  jsondata = (item(i) for i in [0..19])
  data = new poly.Data json:jsondata
  spec = {
    layers: [
      { data: data, type: 'area', x : 'index', y : 'value', color: 'even'}
    ]
    guides:
      y :
        type:'num', min:0, max:15
      color:
        title: "Parity"
    dom: dom
  }
  c = poly.chart spec

  update = () ->
    for j in [1,2]
      jsondata.shift()
      jsondata.push(item(i))
      i++
    data.update json:jsondata
    setTimeout(update, 1000)
  setTimeout(update, 1000)

  c.addHandler (type, e) -> if type == 'data' then c.make()


