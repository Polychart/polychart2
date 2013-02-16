@examples ?= {}

data = polyjs.data json:({index:i, k:""+i%2, value:Math.random()*10} for i in [0..10])

@examples.test_layerchange = (dom) ->
  spec1 = {
    layer:
      data: data
      type: 'point'
      x: 'index'
      y: 'value'
      color: 'k'
    dom: dom
  }
  spec2 = {
    layer:
      data: data
      type: 'bar'
      x: 'bin(index,1)'
      y: 'value'
      color: 'k'
    dom: dom
  }
  t = 1
  c = polyjs.chart spec1
  c.addHandler (type, e) ->
    data = e.evtData
    if type == 'reset'
      if t is 1
        c.make spec2
        t = 2
      else
        c.make spec1
        t = 1

@examples.test_facetchange = (dom) ->
  spec1 = {
    layer:
      data: data
      type: 'point'
      x: 'index'
      y: 'value'
      color: 'k'
    dom: dom
  }
  spec2 = {
    layer:
      data: data
      type: 'bar'
      x: 'bin(index,2)'
      y: 'value'
      color: 'k'
    dom: dom
    facet:
      type: 'wrap'
      var: 'k'
  }
  t = 1
  c = polyjs.chart spec1
  c.addHandler (type, e) ->
    data = e.evtData
    if type == 'reset'
      if t is 1
        c.make spec2
        t = 2
      else
        c.make spec1
        t = 1

@examples.test_coordchange = (dom) ->
  spec1 = {
    layer:
      data: data
      type: 'point'
      x: 'index'
      y: 'value'
      color: 'k'
    dom: dom
  }
  spec2 = {
    layer:
      data: data
      type: 'bar'
      x: 'bin(index,2)'
      y: 'value'
      color: 'k'
    dom: dom
    coord:
      type: 'polar'
  }
  t = 1
  c = polyjs.chart spec1
  c.addHandler (type, e) ->
    data = e.evtData
    if type == 'reset'
      if t is 1
        c.make spec2
        t = 2
      else
        c.make spec1
        t = 1

@examples.test_coordfacet = (dom) ->
  spec1 = {
    layer:
      data: data
      type: 'point'
      x: 'index'
      y: 'value'
      color: 'k'
    dom: dom
  }
  spec2 = {
    layer:
      data: data
      type: 'bar'
      x: 'bin(index,2)'
      y: 'value'
      color: 'k'
    dom: dom
    coord:
      type: 'polar'
    facet:
      type: 'wrap'
      var: 'k'
  }
  t = 1
  c = polyjs.chart spec1
  c.addHandler (type, e) ->
    data = e.evtData
    if type == 'reset'
      if t is 1
        c.make spec2
        t = 2
      else
        c.make spec1
        t = 1

