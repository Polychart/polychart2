@examples ?= {}

@examples.facet = (dom) ->
  o = (i) -> if i%2 is 0 then 'yay' else 'no'
  jsondata = ({index:i%3, value:Math.random()*10, o: o(i)} for i in [0..10])
  data = new polyjs.Data json:jsondata
  spec = {
    layers: [
      data: data, type: 'bar',
      x : 'bin(index,1)', y : 'value', color: 'o'
      position:'dodge'
    ]
    dom: dom
    facet:
      type: 'wrap'
      var: 'o'
    width: 600
    height: 200

  }
  c = polyjs.chart spec

@examples.facet_grid = (dom) ->
  o = (i) -> if i%2 is 0 then 'yay' else 'no'
  jsondata = ({index:i%3, value:Math.random()*10, o: o(i)} for i in [0..10])
  data = new polyjs.Data json:jsondata
  spec = {
    layers: [
      data: data, type: 'bar',
      x : 'bin(index,1)', y : 'value'
      position:'dodge'
    ]
    dom: dom
    facet:
      type: 'wrap'
      var: 'o'
    width: 600
    height: 200

  }
  c = polyjs.chart spec

