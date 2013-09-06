@examples ?= {}

@examples.facet = (dom) ->
  o = (i) -> if i%3 is 0 then 'yay' else if i%3 is 1 then 'no' else 'nodisplay'
  jsondata = ({index:i%7, value:Math.random()*10, o: o(i)} for i in [0..20])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      data: data, type: 'bar',
      x : 'bin(index,1)', y : 'value', color: 'o'
      position:'dodge'
    ]
    dom: dom
    facet:
      type: 'wrap'
      var: {var: 'o', levels: ['yay', 'no']}
      formatter: (x) -> if x.o is 'yay' then 'First Group' else 'Second Group'
    width: 600
    height: 200

  }
  c = polyjs.chart spec

@examples.facet_bracketed = (dom) ->
  o = (i) -> if i%3 is 0 then 'yay' else if i%3 is 1 then 'no' else 'nodisplay'
  jsondata = ({index:i%7, value:Math.random()*10, o: o(i)} for i in [0..20])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      data: data, type: 'bar',
      x : 'bin(index,1)', y : 'value', color: 'o'
      position:'dodge'
    ]
    dom: dom
    facet:
      type: 'wrap'
      var: {var: '[o]', levels: ['yay', 'no']}
      formatter: (x) -> if x.o is 'yay' then 'First Group' else 'Second Group'
    width: 600
    height: 200

  }
  c = polyjs.chart spec

@examples.facet_grid = (dom) ->
  o = (i) -> if i%2 is 0 then 'yay' else 'no'
  jsondata = ({index:i%3, value:Math.random()*10, o: o(i)} for i in [0..10])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      data: data, type: 'bar',
      x : 'bin(index,1)', y : 'value'
      position:'dodge'
    ]
    dom: dom
    facet:
      type: 'grid'
      x: '[o]'
      y: 'o'
    width: 600
    height: 500

  }
  c = polyjs.chart spec

@examples.facet3 = (dom) ->
  o = (i) -> ""+i%6
  jsondata = ({index:i%7, value:Math.random()*10, o: o(i)} for i in [0..50])
  data = polyjs.data data:jsondata
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
    height: 500

  }
  c = polyjs.chart spec

@examples.facet4 = (dom) ->
  o = (i) -> ""+i%3
  p = (i) -> ""+i%2
  jsondata = ({index:i%6, value:Math.random()*10, o: o(i), p:p(i)} for i in [0..50])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      data: data, type: 'bar',
      x : 'bin(index,1)', y : 'value'
      position:'dodge'
    ]
    dom: dom
    facet:
      type: 'grid'
      x: 'o'
      y: '[p]'
    width: 600
    height: 500

  }
  c = polyjs.chart spec

@examples.facet_polar = (dom) ->
  o = (i) -> ""+i%3
  p = (i) -> ""+i%2
  jsondata = ({index:i%6, value:Math.random()*10, o: o(i), p:p(i)} for i in [0..50])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      data: data, type: 'bar',
      x : 'bin(index,1)', y : 'value'
      position:'dodge'
    ]
    coord: { type: 'polar' }
    dom: dom
    facet:
      type: 'grid'
      x: 'o'
      y: 'p'
    width: 600
    height: 500

  }
  c = polyjs.chart spec

@examples.facet_polar_wrap = (dom) ->
  o = (i) -> ""+i%6
  jsondata = ({index:i%7, value:Math.random()*10, o: o(i)} for i in [0..50])
  data = polyjs.data data:jsondata
  spec = {
    layers: [
      data: data, type: 'bar',
      x : 'bin(index,1)', y : 'value'
      color: 'o'
      position:'dodge'
    ]
    coord: { type: 'polar', flip:true }
    dom: dom
    facet:
      type: 'wrap'
      var: 'o'
    width: 600
    height: 500

  }
  c = polyjs.chart spec


